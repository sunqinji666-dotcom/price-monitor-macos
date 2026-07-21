import Foundation

enum StoreAPIError: LocalizedError {
    case invalidResponse
    case service(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "店铺返回的数据无法识别"
        case .service(let message): return message
        }
    }
}

struct StoreAPI {
    private let endpoint = URL(string: "https://pay.ldxp.cn/shopApi/Shop/goodsList")!

    func fetchProducts(for shop: Shop) async throws -> [Product] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("PriceMonitor/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20
        request.httpBody = try JSONEncoder().encode(RequestBody(token: shop.token))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw StoreAPIError.invalidResponse
        }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard result.code == 1, let payload = result.data else {
            throw StoreAPIError.service(message: result.msg)
        }
        return payload.list.map { item in
            Product(
                id: "\(shop.token)-\(item.goodsKey)", shop: shop, name: item.name,
                link: URL(string: item.link)!,
                category: item.category?.name ?? "未分类", price: item.price,
                marketPrice: item.marketPrice ?? 0, stockCount: item.extend?.stockCount ?? 0
            )
        }
    }
}

private struct RequestBody: Encodable {
    let token: String
    let keywords = ""
    let goodsType = "card"
    let current = 1
    let pageSize = 100

    enum CodingKeys: String, CodingKey { case token, keywords, goodsType = "goods_type", current, pageSize }
}

private struct Response: Decodable {
    let code: Int
    let msg: String
    let data: Payload?
}

private struct Payload: Decodable { let list: [APIProduct] }
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
