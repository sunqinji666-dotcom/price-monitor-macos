import Foundation

/// PriceAI 提供的公开聚合报价：不依赖 LDXP 的人机验证，可作为独立价格来源。
struct PriceAIAPI {
    private let endpoint = URL(string: "https://priceai.cc/api/products/chatgpt-team-business/offers")!
    private let pageSize = 30
    private let shop = Shop(token: "priceai-chatgpt-team-business", displayName: "PriceAI · Team/Business")

    func fetchProducts() async throws -> [Product] {
        var offset = 0
        var products: [Product] = []
        var expectedTotal: Int?

        while true {
            var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "limit", value: String(pageSize)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
            var request = URLRequest(url: components.url!)
            request.setValue("PriceMonitor/1.5", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw StoreAPIError.invalidResponse
            }
            let page = try JSONDecoder().decode(PriceAIResponse.self, from: data)
            expectedTotal = expectedTotal ?? page.total
            products += page.offers.compactMap { offer in
                guard let link = URL(string: offer.url) else { return nil }
                return Product(
                    id: "priceai-\(offer.id)",
                    shop: shop,
                    name: offer.sourceTitle,
                    link: link,
                    category: priceAICategory(for: offer),
                    price: offer.price,
                    marketPrice: 0,
                    stockCount: offer.stockCount ?? 0
                )
            }
            offset += page.offers.count
            if page.offers.isEmpty || page.offers.count < pageSize || (expectedTotal.map { offset >= $0 } ?? false) {
                return products
            }
        }
    }

    private func priceAICategory(for offer: PriceAIOffer) -> String {
        let tags = offer.tags.joined(separator: " · ")
        return tags.isEmpty ? "ChatGPT Team / Business" : "ChatGPT Team / Business · \(tags)"
    }
}

private struct PriceAIResponse: Decodable {
    let total: Int?
    let offers: [PriceAIOffer]
}

private struct PriceAIOffer: Decodable {
    let id: String
    let url: String
    let tags: [String]
    let price: Decimal
    let sourceTitle: String
    let stockCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, url, tags, price, sourceTitle, stockCount
    }
}
