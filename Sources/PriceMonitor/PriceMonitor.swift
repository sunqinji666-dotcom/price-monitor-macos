import Foundation
import SwiftUI

@MainActor
final class PriceMonitor: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published var autoRefreshMinutes = 1

    private let api = StoreAPI()
    private var refreshTask: Task<Void, Never>?
    private var timer: Timer?
    private var knownAvailableProductIDs = Set<String>()
    private var hasLoadedInitialProducts = false

    init() { configureAutoRefresh() }

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
            defer { isRefreshing = false }
            do {
                var all: [Product] = []
                for shop in Shop.defaults {
                    all += try await api.fetchProducts(for: shop)
                }
                let currentlyAvailable = Set(all.filter(\.inStock).map(\.id))
                let newlyAvailable = all.filter { $0.inStock && !knownAvailableProductIDs.contains($0.id) }
                if hasLoadedInitialProducts, !newlyAvailable.isEmpty {
                    let names = newlyAvailable.prefix(3).map { "\($0.shop.displayName)的\($0.name)，价格\($0.priceText)" }
                    let extra = newlyAvailable.count > 3 ? "，另有\(newlyAvailable.count - 3)件" : ""
                    SpeechAnnouncer.shared.speak("发现新货上架：\(names.joined(separator: "；"))\(extra)。")
                }
                knownAvailableProductIDs = currentlyAvailable
                hasLoadedInitialProducts = true
                products = all
                lastUpdated = Date()
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func configureAutoRefresh() {
        timer?.invalidate()
        guard autoRefreshMinutes > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoRefreshMinutes * 60), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
}
