import SwiftUI
import WebKit

/// 仅保存 LDXP 网站在本机验证后写入的 Cookie，用于同域商品接口请求。
/// 不读取浏览器密码、账户信息或其他网站 Cookie。
@MainActor
final class StoreVerificationSession: ObservableObject {
    static let shared = StoreVerificationSession()

    let store = WKWebsiteDataStore.default()
    @Published private(set) var isSynchronizing = false
    @Published private(set) var status = "请在下方网页中手动完成验证。"

    private init() { }

    func syncCookies() async -> Bool {
        isSynchronizing = true
        defer { isSynchronizing = false }
        let cookies = await withCheckedContinuation { continuation in
            store.httpCookieStore.getAllCookies { continuation.resume(returning: $0) }
        }
        let ldxpCookies = cookies.filter { $0.domain.contains("ldxp.cn") }
        ldxpCookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
        let hasVerificationCookie = ldxpCookies.contains { $0.name == "acw_tc" || $0.name == "cdn_sec_tc" }
        status = hasVerificationCookie
            ? "验证会话已同步，可以刷新价格。"
            : "尚未检测到验证会话，请先在网页中完成验证。"
        return hasVerificationCookie
    }
}

struct StoreVerificationView: View {
    @EnvironmentObject private var monitor: PriceMonitor
    @StateObject private var session = StoreVerificationSession.shared
    @State private var selectedShop = Shop.defaults.last?.token ?? ""

    private var shop: Shop {
        Shop.defaults.first(where: { $0.token == selectedShop }) ?? Shop.defaults[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("网站人工验证").font(.headline)
                    Text(session.status).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("店铺", selection: $selectedShop) {
                    ForEach(Shop.defaults) { shop in
                        Text(shop.displayName).tag(shop.token)
                    }
                }
                .frame(width: 150)
                Button(session.isSynchronizing ? "同步中…" : "验证完成并刷新") {
                    Task {
                        guard await session.syncCookies() else { return }
                        monitor.refresh()
                    }
                }
                .disabled(session.isSynchronizing)
                .buttonStyle(.borderedProminent)
            }
            .padding(16)

            Text("当页面出现滑块或真人验证时，请你亲自完成。程序不会自动绕过验证；成功后点击右侧按钮让价格监控复用本机验证会话。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()
            StoreVerificationWebView(url: URL(string: "https://pay.ldxp.cn/shop/\(shop.token)")!, store: session.store)
        }
    }
}

private struct StoreVerificationWebView: NSViewRepresentable {
    let url: URL
    let store: WKWebsiteDataStore

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        guard view.url?.path != url.path else { return }
        view.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate { }
}
