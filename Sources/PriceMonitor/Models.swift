import Foundation

struct Shop: Identifiable, Hashable {
    let token: String
    let displayName: String

    var id: String { token }

    static let defaults = [
        Shop(token: "2GO2Z6GD", displayName: "ppgpt"),
        Shop(token: "K1PKHQ1F", displayName: "Yonnani"),
        Shop(token: "mlxggpt", displayName: "麻辣香锅AI杂货铺")
    ]
}

struct Product: Identifiable, Hashable {
    let id: String
    let shop: Shop
    let name: String
    let link: URL
    let category: String
    let price: Decimal
    let marketPrice: Decimal
    let stockCount: Int

    var inStock: Bool { stockCount > 0 }
    var stockText: String { inStock ? "剩余 \(stockCount) 件" : "缺货" }
    /// 将不同店铺的同类商品放到同一列，便于直接比价。
    var comparisonGroup: String {
        let text = "\(name) \(category)".lowercased()
        if text.contains("codex") && text.contains("接码") { return "Codex 接码" }
        if text.contains("gemini") { return "Gemini" }
        if text.contains("grok") { return "Grok" }
        if text.contains("chatgpt pro") || text.contains("gpt pro") { return "ChatGPT Pro" }
        if text.contains("chatgpt plus") || text.contains("gpt plus") || text.contains("gptplus") || text.contains("plus") { return "ChatGPT Plus" }
        if text.contains("接码") { return "接码服务" }
        if text.contains("邮箱") || text.contains("mail") { return "邮箱" }
        return category.isEmpty ? "其他" : category
    }

    var comparisonGroupOrder: Int {
        switch comparisonGroup {
        case "ChatGPT Plus": return 0
        case "ChatGPT Pro": return 1
        case "Gemini": return 2
        case "Grok": return 3
        case "Codex 接码": return 4
        case "接码服务": return 5
        case "邮箱": return 6
        default: return 99
        }
    }
    var priceText: String {
        let number = NSDecimalNumber(decimal: price)
        return "¥" + NumberFormatter.price.string(from: number)!
    }
}

extension NumberFormatter {
    static let price: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
