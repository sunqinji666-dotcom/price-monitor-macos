import Foundation

enum StoreAPIError: LocalizedError {
    case invalidResponse
    case verificationRequired
    case service(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "店铺返回的数据无法识别"
        case .verificationRequired: return "店铺要求人工验证，请打开“网站验证”完成后再刷新"
        case .service(let message): return message
        }
    }
}

struct StoreAPI {
    private let endpoint = URL(string: "https://pay.ldxp.cn/shopApi/Shop/goodsList")!
    /// 留出余量，避免服务端即使悄悄降低单页上限也漏掉后面的新商品。
    private let pageSize = 50

    private var session: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }

    func fetchProducts(for shop: Shop) async throws -> [Product] {
        var currentPage = 1
        var products: [Product] = []
        var seenIDs = Set<String>()

        while true {
            let payload = try await fetchPage(for: shop, current: currentPage)
            let pageProducts = payload.list.compactMap { item -> Product? in
                // 重复条目不应该导致同一商品在界面或新货提醒中出现两次。
                guard seenIDs.insert(item.goodsKey).inserted, let link = URL(string: item.link) else { return nil }
                return Product(
                    id: "\(shop.token)-\(item.goodsKey)", shop: shop, name: item.name,
                    link: link, category: item.category?.name ?? "未分类", price: item.price,
                    marketPrice: item.marketPrice ?? 0, stockCount: item.extend?.stockCount ?? 0
                )
            }
            products += pageProducts

            // total 是服务端的完整计数；同时用空页和短页作保护，防止异常响应造成死循环。
            if products.count >= payload.total || payload.list.isEmpty || payload.list.count < pageSize {
                return products
            }
            currentPage += 1
        }
    }

    private func fetchPage(for shop: Shop, current: Int) async throws -> Payload {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/18.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("https://pay.ldxp.cn", forHTTPHeaderField: "Origin")
        request.setValue("https://pay.ldxp.cn/shop/\(shop.token)", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 20
        request.httpBody = try JSONEncoder().encode(RequestBody(token: shop.token, current: current, pageSize: pageSize))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw StoreAPIError.invalidResponse
        }
        if let html = String(data: data, encoding: .utf8)?.lowercased(),
           html.contains("aliyuncaptcha") || html.contains("waf_nc") || html.contains("captcha-element") {
            throw StoreAPIError.verificationRequired
        }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard result.code == 1, let payload = result.data else {
            throw StoreAPIError.service(message: result.msg)
        }
        return payload
    }
}

private struct RequestBody: Encodable {
    let token: String
    let keywords = ""
    let goodsType = "card"
    let current: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey { case token, keywords, goodsType = "goods_type", current, pageSize }
}

private struct Response: Decodable {
    let code: Int
    let msg: String
    let data: Payload?
}

private struct Payload: Decodable {
    let total: Int
    let list: [APIProduct]
}
private struct APIProduct: Decodable {
    let goodsKey: String
    let name: String
    let link: String
    let price: Decimal
    let marketPrice: Decimal?
    let category: Category?
    let extend: Stock?

    enum CodingKeys: String, CodingKey { case goodsKey = "goods_key", name, link, price, marketPrice = "market_price", category, extend }
}
private struct Category: Decodable { let name: String }
private struct Stock: Decodable {
    let stockCount: Int
    enum CodingKeys: String, CodingKey { case stockCount = "stock_count" }
}
