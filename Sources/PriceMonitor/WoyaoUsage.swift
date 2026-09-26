import Foundation
import SwiftUI

private enum RightAPILocalKeyFile {
    private static let folderName = "价格监控"
    private static let fileName = "rightapi-api-key.txt"
    private static let legacyFileName = "right-codes-api-key.txt"

    private static var folderURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folderName, isDirectory: true)
    }

    static var fileURL: URL { folderURL.appendingPathComponent(fileName) }

    private static var legacyFileURL: URL { folderURL.appendingPathComponent(legacyFileName) }

    static func load() -> String? {
        let source = FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : legacyFileURL
        guard let value = try? String(contentsOf: source, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }

    static func save(_ key: String) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try Data(key.utf8).write(to: fileURL, options: .atomic)
        try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    static func remove() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}

private struct RightAPIClient {
    private let baseURL = URL(string: "https://www.rightapi.ai")!

    func load(key: String) async throws -> RightAPISummary {
        try await request(path: "/account/summary", key: key, as: RightAPISummary.self)
    }

    private func request<T: Decodable>(path: String, key: String, as type: T.Type) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RightAPIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw RightAPIError.http(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

}

private enum RightAPIError: LocalizedError {
    case invalidResponse
    case http(Int)
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "RightAPI 返回的数据无法识别"
        case .http(401): return "RightAPI Key 无效或已失效"
        case .http(let status): return "RightAPI 请求失败（HTTP \(status)）"
        }
    }
}

struct FlexibleNumber: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) { value = number; return }
        if let number = try? container.decode(Int.self) { value = Double(number); return }
        if let text = try? container.decode(String.self), let number = Double(text) { value = number; return }
        value = 0
    }
}

struct RightAPISummary: Decodable {
    let balance: FlexibleNumber
    let totalRecharge: FlexibleNumber?
    let totalConsumption: FlexibleNumber?

    enum CodingKeys: String, CodingKey {
        case balance
        case totalRecharge = "total_recharge"
        case totalConsumption = "total_consumption"
    }
}

@MainActor
final class RightAPIUsageMonitor: ObservableObject {
    @Published var keyInput = ""
    @Published private(set) var hasStoredKey = false
    @Published private(set) var summary: RightAPISummary?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published var monitorIntervalMinutes: Int {
        didSet {
            let normalized = min(1440, max(1, monitorIntervalMinutes))
            if normalized != monitorIntervalMinutes { monitorIntervalMinutes = normalized; return }
            UserDefaults.standard.set(monitorIntervalMinutes, forKey: MonitorPreference.rightAPIRefreshMinutes)
        }
    }

    private let client = RightAPIClient()
    private var hourlyTimer: Timer?

    init() {
        let savedMinutes = UserDefaults.standard.integer(forKey: MonitorPreference.rightAPIRefreshMinutes)
        monitorIntervalMinutes = savedMinutes > 0 ? min(1440, savedMinutes) : 60
        hasStoredKey = RightAPILocalKeyFile.load() != nil
        if hasStoredKey {
            refresh()
            configureMonitoring()
        }
    }

    var menuBarTitle: String {
        guard let balance = summary?.balance.value else { return "余额 —" }
        return String(format: "余额 $%.2f", balance)
    }

    var menuBarDetail: String {
        guard let balance = summary?.balance.value else { return "RightAPI 余额暂未读取" }
        return String(format: "RightAPI 当前余额：$%.4f", balance)
    }

    func saveAndRefresh() {
        let key = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { errorMessage = "请先粘贴 RightAPI API Key"; return }
        do {
            try RightAPILocalKeyFile.save(key)
            keyInput = ""
            hasStoredKey = true
            refresh()
            configureMonitoring()
        } catch { errorMessage = error.localizedDescription }
    }

    func refresh(shouldAnnounce: Bool = false) {
        guard !isRefreshing, let key = RightAPILocalKeyFile.load() else { return }
        isRefreshing = true
        errorMessage = nil
        Task {
            defer { isRefreshing = false }
            do {
                let result = try await client.load(key: key)
                summary = result
                lastUpdated = Date()
                if shouldAnnounce { announceCurrentUsage(result) }
            } catch is DecodingError {
                errorMessage = "RightAPI 返回的数据格式有更新，请刷新后重试。"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func removeKey() {
        do {
            try RightAPILocalKeyFile.remove()
            hasStoredKey = false
            summary = nil
            hourlyTimer?.invalidate()
            hourlyTimer = nil
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func configureMonitoring() {
        hourlyTimer?.invalidate()
        hourlyTimer = nil
        guard MonitorPreference.bool(MonitorPreference.timedMonitoringEnabled), hasStoredKey else { return }
        hourlyTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(monitorIntervalMinutes * 60), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh(shouldAnnounce: true) }
        }
    }

    private func announceCurrentUsage(_ usage: RightAPISummary) {
        SpeechAnnouncer.shared.alert(
            title: "RightAPI 余额更新",
            body: "当前余额 \(currency(usage.balance.value))，累计充值 \(currency(usage.totalRecharge?.value ?? 0))，累计消费 \(currency(usage.totalConsumption?.value ?? 0))。",
            category: .balance
        )
    }

    private func currency(_ value: Double) -> String { String(format: "%.2f 美元", value) }
}

struct RightAPIUsageView: View {
    @EnvironmentObject private var monitor: RightAPIUsageMonitor

    var body: some View {
        Group {
            if !monitor.hasStoredKey {
                keySetup
            } else {
                usageDashboard
            }
        }
        .padding(20)
    }

    private var keySetup: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield").font(.system(size: 36)).foregroundStyle(.blue)
            Text("连接 RightAPI 余额监控").font(.title2.bold())
            Text("粘贴你的 API Key 后，工具会保存到本机“文档/价格监控/rightapi-api-key.txt”。\n旧的 right-codes-api-key.txt 会自动兼容读取；不会从浏览器读取，也不会写入日志。")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            SecureField("sk-…", text: $monitor.keyInput).textFieldStyle(.roundedBorder).frame(maxWidth: 420)
            Button("保存到文档并读取") { monitor.saveAndRefresh() }.buttonStyle(.borderedProminent)
            if let error = monitor.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var usageDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
            Text("RightAPI 余额监控").font(.title2.bold())
                    Text(statusText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("刷新", systemImage: "arrow.clockwise") { monitor.refresh() }.disabled(monitor.isRefreshing)
                Button("移除 Key", role: .destructive) { monitor.removeKey() }
            }
            if let summary = monitor.summary {
                HStack(spacing: 12) {
                    metric("当前余额", currency(summary.balance.value), "creditcard")
                    metric("累计充值", currency(summary.totalRecharge?.value ?? 0), "plus.circle")
                    metric("累计消费", currency(summary.totalConsumption?.value ?? 0), "chart.bar")
                }
            } else if monitor.errorMessage == nil {
                ProgressView("正在读取 RightAPI 余额…").frame(maxWidth: .infinity, minHeight: 90)
            } else {
                ContentUnavailableView("读取失败", systemImage: "exclamationmark.triangle", description: Text(monitor.errorMessage ?? "未知错误"))
                    .frame(maxWidth: .infinity, minHeight: 90)
            }
            Text("数据来自 RightAPI `/account/summary`。点击“刷新”可手动更新。")
                .font(.caption).foregroundStyle(.secondary)
            if monitor.summary != nil, let error = monitor.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
        }
    }

    private func metric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.monospacedDigit().bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func currency(_ value: Double) -> String { String(format: "$%.4f", value) }
    private var statusText: String {
        if monitor.isRefreshing { return "正在更新…" }
        guard let date = monitor.lastUpdated else { return "已连接，等待刷新" }
        return "更新于 \(date.formatted(date: .omitted, time: .shortened)) · 每 \(monitor.monitorIntervalMinutes) 分钟自动更新 · Key 存于本机文档"
    }
}
