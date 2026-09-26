import Foundation
import SwiftUI

@MainActor
final class PriceMonitor: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var requiresVerification = false
    @Published var autoRefreshMinutes: Int {
        didSet {
            let normalized = min(1440, max(1, autoRefreshMinutes))
            if normalized != autoRefreshMinutes { autoRefreshMinutes = normalized; return }
            UserDefaults.standard.set(autoRefreshMinutes, forKey: MonitorPreference.productRefreshMinutes)
        }
    }

    private let api = StoreAPI()
    private let priceAIAPI = PriceAIAPI()
    private var refreshTask: Task<Void, Never>?
    private var timer: Timer?
    private var knownAvailableProductIDs = Set<String>()
    private var hasLoadedInitialProducts = false

    init() {
        let savedMinutes = UserDefaults.standard.integer(forKey: MonitorPreference.productRefreshMinutes)
        autoRefreshMinutes = savedMinutes > 0 ? min(1440, savedMinutes) : 1
        configureAutoRefresh()
    }

    var menuBarSymbol: String {
        if isRefreshing { return "arrow.triangle.2.circlepath" }
        return products.contains(where: \.inStock) ? "tag.fill" : "tag"
    }

    func refresh() {
        guard !isRefreshing else { return }
        refreshTask?.cancel()
        refreshTask = Task {
            isRefreshing = true
            errorMessage = nil
            requiresVerification = false
            defer { isRefreshing = false }
            var all: [Product] = []
            var failures: [String] = []
            for shop in Shop.defaults {
                do {
                    all += try await api.fetchProducts(for: shop)
                } catch is CancellationError {
                    return
                } catch StoreAPIError.verificationRequired {
                    all += products.filter { $0.shop == shop }
                    failures.append("\(shop.displayName)：需要人工验证")
                    requiresVerification = true
                } catch {
                    // 某一家临时超时不能让另两家停止更新；保留上一轮该店数据，下一轮继续重试。
                    all += products.filter { $0.shop == shop }
                    failures.append("\(shop.displayName)：\(error.localizedDescription)")
                }
            }
            do {
                all += try await priceAIAPI.fetchProducts()
            } catch is CancellationError {
                return
            } catch {
                all += products.filter { $0.shop.token == "priceai-chatgpt-team-business" }
                failures.append("PriceAI · Team/Business：\(error.localizedDescription)")
            }
            let currentlyAvailable = Set(all.filter(\.inStock).map(\.id))
            let newlyAvailable = all.filter { $0.inStock && !knownAvailableProductIDs.contains($0.id) }
            if hasLoadedInitialProducts, !newlyAvailable.isEmpty {
                let includePrice = MonitorPreference.bool(MonitorPreference.speakProductPrice)
                let describe: (Product) -> String = { product in
                    includePrice
                        ? "\(product.shop.displayName)的\(product.name)，价格\(product.priceText)"
                        : "\(product.shop.displayName)的\(product.name)"
                }
                let names = newlyAvailable.prefix(3).map(describe)
                let extra = newlyAvailable.count > 3 ? "，另有\(newlyAvailable.count - 3)件" : ""
                let speechProducts = newlyAvailable.filter { MonitorPreference.productSpeechAllows($0.comparisonGroup) }
                let speechNames = speechProducts.prefix(3).map(describe)
                let speechExtra = speechProducts.count > 3 ? "，另有\(speechProducts.count - 3)件" : ""
                let spokenBody = speechProducts.isEmpty
                    ? ""
                    : "\(speechNames.joined(separator: "；"))\(speechExtra)"
                SpeechAnnouncer.shared.alert(
                    title: "价格监控：发现新货",
                    body: "\(names.joined(separator: "；"))\(extra)",
                    category: .product,
                    spokenBody: spokenBody
                )
            }
            knownAvailableProductIDs = currentlyAvailable
            hasLoadedInitialProducts = true
            products = all
            lastUpdated = Date()
            errorMessage = failures.isEmpty ? nil : failures.joined(separator: "；")
        }
    }

    func configureAutoRefresh() {
        timer?.invalidate()
        guard MonitorPreference.bool(MonitorPreference.timedMonitoringEnabled), autoRefreshMinutes > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoRefreshMinutes * 60), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
}
