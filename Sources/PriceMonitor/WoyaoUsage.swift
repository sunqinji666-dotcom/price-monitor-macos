import Foundation
import SwiftUI

private enum WoyaoLocalKeyFile {
    private static let folderName = "价格监控"
    private static let fileName = "woyao-api-key.txt"

    private static var folderURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folderName, isDirectory: true)
    }

    static var fileURL: URL { folderURL.appendingPathComponent(fileName) }

    static func load() -> String? {
        guard let value = try? String(contentsOf: fileURL, encoding: .utf8)
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

private struct WoyaoClient {
    private let baseURL = URL(string: "https://woyao.pro")!

    func load(key: String) async throws -> (WoyaoSnapshot, [WoyaoLog]) {
        let usage = try await request(path: "/api/proxy/v1/usage", key: key, as: WoyaoUsageResponse.self)
        let logs = (try? await requestLogs(key: key)) ?? []
        return (usage.toSnapshot, logs)
    }

    private func request<T: Decodable>(path: String, key: String, as type: T.Type) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WoyaoError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw WoyaoError.http(http.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestLogs(key: String) async throws -> [WoyaoLog] {
        let calendar = Calendar.current
        let today = Date()
        let start = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var components = URLComponents(url: baseURL.appending(path: "/api/usage-logs"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "10"),
            URLQueryItem(name: "start_date", value: formatter.string(from: start)),
            URLQueryItem(name: "end_date", value: formatter.string(from: today))
        ]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WoyaoError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw WoyaoError.http(http.statusCode) }
        return try JSONDecoder().decode(WoyaoLogsResponse.self, from: data).data
            .sorted { $0.createdAt > $1.createdAt }
    }
}

private enum WoyaoError: LocalizedError {
    case invalidResponse
    case http(Int)
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "WOYAO 返回的数据无法识别"
        case .http(401): return "API Key 无效或已失效"
        case .http(let status): return "WOYAO 请求失败（HTTP \(status)）"
        }
    }
}

private struct FlexibleNumber: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) { value = number; return }
        if let number = try? container.decode(Int.self) { value = Double(number); return }
        if let text = try? container.decode(String.self), let number = Double(text) { value = number; return }
        value = 0
    }
}

private struct WoyaoUsageResponse: Decodable {
    let remaining: FlexibleNumber
    let quota: WoyaoQuota?
    let usage: WoyaoUsage?

    var toSnapshot: WoyaoSnapshot {
        WoyaoSnapshot(
            remaining: remaining.value,
            limit: quota?.limit.value,
            used: quota?.used.value,
            todayCost: usage?.today?.cost.value,
            totalCost: usage?.total?.cost.value
        )
    }
}
private struct WoyaoQuota: Decodable { let used: FlexibleNumber; let limit: FlexibleNumber }
private struct WoyaoUsage: Decodable { let today: WoyaoUsageMetric?; let total: WoyaoUsageMetric? }
private struct WoyaoUsageMetric: Decodable { let cost: FlexibleNumber }
private struct WoyaoLogsResponse: Decodable { let data: [WoyaoLog] }
struct WoyaoLog: Decodable, Identifiable {
    let id: String
    let model: String
    let totalCost: Double
    let inputTokens: Double
    let outputTokens: Double
    let cacheReadTokens: Double
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, model
        case totalCost = "total_cost"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let numericID = try? container.decode(FlexibleNumber.self, forKey: .id) {
            id = String(numericID.value)
        } else {
            id = UUID().uuidString
        }
        model = (try? container.decode(String.self, forKey: .model)) ?? "未知模型"
        totalCost = (try? container.decode(FlexibleNumber.self, forKey: .totalCost).value) ?? 0
        inputTokens = (try? container.decode(FlexibleNumber.self, forKey: .inputTokens).value) ?? 0
        outputTokens = (try? container.decode(FlexibleNumber.self, forKey: .outputTokens).value) ?? 0
        cacheReadTokens = (try? container.decode(FlexibleNumber.self, forKey: .cacheReadTokens).value) ?? 0
        createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? "时间未知"
    }
}
struct WoyaoSnapshot {
    let remaining: Double
    let limit: Double?
    let used: Double?
    let todayCost: Double?
    let totalCost: Double?

    var spent: Double? { used ?? limit.map { $0 - remaining } }
}

@MainActor
final class WoyaoUsageMonitor: ObservableObject {
    @Published var keyInput = ""
    @Published private(set) var hasStoredKey = false
    @Published private(set) var snapshot: WoyaoSnapshot?
    @Published private(set) var logs: [WoyaoLog] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let client = WoyaoClient()
    private var hourlyTimer: Timer?

    init() {
        hasStoredKey = WoyaoLocalKeyFile.load() != nil
        if hasStoredKey {
            refresh()
            startHourlyReporting()
        }
    }

    var menuBarTitle: String {
        guard let balance = snapshot?.remaining else { return "余额 —" }
        return String(format: "余额 $%.2f", balance)
    }

    var menuBarDetail: String {
        guard let balance = snapshot?.remaining else { return "WOYAO 余额暂未读取" }
        return String(format: "WOYAO 当前余额：$%.4f", balance)
    }

    func saveAndRefresh() {
        let key = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { errorMessage = "请先粘贴 WOYAO API Key"; return }
        do {
            try WoyaoLocalKeyFile.save(key)
            keyInput = ""
            hasStoredKey = true
            refresh()
            startHourlyReporting()
        } catch { errorMessage = error.localizedDescription }
    }

    func refresh(shouldAnnounce: Bool = false) {
        guard !isRefreshing, let key = WoyaoLocalKeyFile.load() else { return }
        isRefreshing = true
        errorMessage = nil
        Task {
            defer { isRefreshing = false }
            do {
                let result = try await client.load(key: key)
                snapshot = result.0
                logs = result.1
                lastUpdated = Date()
                if shouldAnnounce { announceCurrentUsage(result.0) }
            } catch is DecodingError {
                errorMessage = "WOYAO 返回的数据格式有更新，请刷新后重试。"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func removeKey() {
        do {
            try WoyaoLocalKeyFile.remove()
            hasStoredKey = false
            snapshot = nil
            logs = []
            hourlyTimer?.invalidate()
            hourlyTimer = nil
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func startHourlyReporting() {
        guard hourlyTimer == nil else { return }
        hourlyTimer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh(shouldAnnounce: true) }
        }
    }

    private func announceCurrentUsage(_ usage: WoyaoSnapshot) {
        let spent = usage.spent ?? 0
        let today = usage.todayCost ?? 0
        SpeechAnnouncer.shared.speak(
            "WOYAO 用量播报：当前余额 \(currency(usage.remaining))，已用额度 \(currency(spent))，今日消费 \(currency(today))。"
        )
    }

    private func currency(_ value: Double) -> String { String(format: "%.2f 美元", value) }
}

struct WoyaoUsageView: View {
    @EnvironmentObject private var monitor: WoyaoUsageMonitor

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
            Text("连接 WOYAO 用量监控").font(.title2.bold())
            Text("粘贴你的 API Key 后，工具会保存到本机“文档/价格监控/woyao-api-key.txt”。\n该文件仅当前 macOS 用户可读写；不会从浏览器读取，也不会写入日志。")
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
                    Text("WOYAO 用量监控").font(.title2.bold())
                    Text(statusText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("刷新", systemImage: "arrow.clockwise") { monitor.refresh() }.disabled(monitor.isRefreshing)
                Button("移除 Key", role: .destructive) { monitor.removeKey() }
            }
            if let snapshot = monitor.snapshot {
                HStack(spacing: 12) {
                    metric("当前余额", currency(snapshot.remaining), "creditcard")
                    metric("已用额度", snapshot.spent.map(currency) ?? "—", "minus.circle")
                    metric("今日消费", snapshot.todayCost.map(currency) ?? "—", "calendar")
                    metric("累计消费", snapshot.totalCost.map(currency) ?? "—", "chart.bar")
                }
                if let limit = snapshot.limit {
                    ProgressView(value: max(0, min(1, 1 - snapshot.remaining / limit)))
                        .tint(snapshot.remaining / limit < 0.1 ? .red : .blue)
                    Text("额度总额 \(currency(limit)) · 当前余额 \(currency(snapshot.remaining))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else if monitor.errorMessage == nil {
                ProgressView("正在读取余额和用量…").frame(maxWidth: .infinity, minHeight: 90)
            } else {
                ContentUnavailableView("读取失败", systemImage: "exclamationmark.triangle", description: Text(monitor.errorMessage ?? "未知错误"))
                    .frame(maxWidth: .infinity, minHeight: 90)
            }
            Text("最近 10 条调用").font(.headline).padding(.top, 4)
            List(monitor.logs) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(log.model).fontWeight(.medium)
                        Text(log.createdAt).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(tokenSummary(log)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Text(currency(log.totalCost)).font(.body.monospacedDigit())
                }
            }
            if monitor.snapshot != nil, let error = monitor.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
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
    private func tokenSummary(_ log: WoyaoLog) -> String {
        return "↓\(compact(log.inputTokens)) ↑\(compact(log.outputTokens)) ☐\(compact(log.cacheReadTokens))"
    }
    private func compact(_ value: Double) -> String {
        value >= 1000 ? String(format: "%.1fK", value / 1000) : String(format: "%.0f", value)
    }
    private var statusText: String {
        if monitor.isRefreshing { return "正在更新…" }
        guard let date = monitor.lastUpdated else { return "已连接，等待刷新" }
        return "更新于 \(date.formatted(date: .omitted, time: .shortened)) · 每小时自动播报 · Key 存于本机文档"
    }
}
