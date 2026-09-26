import SwiftUI
import AppKit

struct MonitorView: View {
    @EnvironmentObject private var monitor: PriceMonitor

    var body: some View {
        TabView {
            StorePriceView()
                .environmentObject(monitor)
                .tabItem { Label("商品价格", systemImage: "tag") }
            RightAPIUsageView()
                .tabItem { Label("RightAPI 余额", systemImage: "chart.line.uptrend.xyaxis") }
            StoreVerificationView()
                .environmentObject(monitor)
                .tabItem { Label("网站验证", systemImage: monitor.requiresVerification ? "checkmark.shield.fill" : "checkmark.shield") }
            AppSettingsView()
                .environmentObject(monitor)
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .padding(.top, 4)
        .background(WindowCloseToBackgroundHandler())
    }
}

/// 接管 SwiftUI 原生窗口：关闭时隐藏到后台（Dock 图标消失），显示时恢复 Dock 图标。
private struct WindowCloseToBackgroundHandler: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            context.coordinator.attach(to: window)
        }
    }

    @MainActor final class Coordinator: NSObject, NSWindowDelegate {
        weak var window: NSWindow?

        func attach(to window: NSWindow) {
            guard self.window !== window else { return }
            self.window?.delegate = nil
            self.window = window
            window.identifier = NSUserInterfaceItemIdentifier("monitor")
            window.isReleasedWhenClosed = false
            AppDelegate.shared?.mainWindow = window
            window.delegate = self
            // 窗口创建晚于代理回调时，这里补一次前台激活，确保 Dock 图标出现。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak window] in
                guard let window, window.isVisible, !CommandLine.arguments.contains("-background") else { return }
                self?.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification, object: window))
            }
        }

        func windowDidBecomeKey(_ notification: Notification) {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            sender.orderOut(nil)
            // 窗口隐藏后隐藏 Dock 图标，程序继续留在右上角菜单栏。
            NSApp.setActivationPolicy(.accessory)
            return false
        }
    }
}

private struct StorePriceView: View {
    @EnvironmentObject private var monitor: PriceMonitor
    @State private var selectedShop = "全部店铺"
    @State private var stockFilter = StockFilter.all
    @State private var keyword = ""

    private enum StockFilter: String, CaseIterable, Identifiable {
        case all = "全部", available = "有货", unavailable = "缺货"
        var id: String { rawValue }
    }

    private var visibleProducts: [Product] {
        monitor.products.filter { product in
            (selectedShop == "全部店铺" || product.shop.displayName == selectedShop)
            && (stockFilter == .all || (stockFilter == .available && product.inStock) || (stockFilter == .unavailable && !product.inStock))
            && (keyword.isEmpty || product.name.localizedCaseInsensitiveContains(keyword) || product.category.localizedCaseInsensitiveContains(keyword) || product.comparisonGroup.localizedCaseInsensitiveContains(keyword))
        }
    }

    private var groupedProducts: [ProductGroup] {
        Dictionary(grouping: visibleProducts, by: \.comparisonGroup)
            .map { ProductGroup(title: $0.key, products: $0.value.sorted { $0.price < $1.price }) }
            .sorted {
                let leftOrder = $0.products.first?.comparisonGroupOrder ?? 99
                let rightOrder = $1.products.first?.comparisonGroupOrder ?? 99
                return leftOrder == rightOrder ? $0.title.localizedStandardCompare($1.title) == .orderedAscending : leftOrder < rightOrder
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filters
            Divider()
            content
        }
        .task { if monitor.products.isEmpty { monitor.refresh() } }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill").foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("价格监控").font(.headline)
                Text(statusText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            TextField("分钟", value: $monitor.autoRefreshMinutes, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 52)
            Text("分钟").font(.caption).foregroundStyle(.secondary)
            .onChange(of: monitor.autoRefreshMinutes) { _, _ in monitor.configureAutoRefresh() }
            Button { monitor.refresh() } label: {
                Label(monitor.isRefreshing ? "刷新中" : "刷新", systemImage: "arrow.clockwise")
            }
            .disabled(monitor.isRefreshing)
            .keyboardShortcut("r", modifiers: .command)
            Button(role: .destructive) { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "xmark.circle")
            }
            .help("退出价格监控")
        }
        .padding(16)
    }

    private var filters: some View {
        HStack {
            Picker("店铺", selection: $selectedShop) {
                Text("全部店铺").tag("全部店铺")
                ForEach(Shop.defaults) { Text($0.displayName).tag($0.displayName) }
                Text("PriceAI · Team/Business").tag("PriceAI · Team/Business")
            }.frame(width: 150)
            Picker("库存", selection: $stockFilter) {
                ForEach(StockFilter.allCases) { Text($0.rawValue).tag($0) }
            }.frame(width: 90)
            TextField("搜索商品或分类", text: $keyword).textFieldStyle(.roundedBorder)
        }
        .padding(12)
    }

    @ViewBuilder private var content: some View {
        if let error = monitor.errorMessage, monitor.products.isEmpty {
            ContentUnavailableView("刷新失败", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if monitor.products.isEmpty {
            ProgressView("正在读取四家店铺…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(groupedProducts) { group in
                    Section("\(group.title) · \(group.products.count) 件") {
                        ForEach(group.products) { product in
                            Button {
                                NSWorkspace.shared.open(product.link)
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name).lineLimit(2)
                                        Text("\(product.shop.displayName) · \(product.category)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(product.priceText).font(.headline.monospacedDigit())
                                    Text(product.stockText)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(product.inStock ? .green : .red)
                                        .frame(width: 72, alignment: .trailing)
                                    Image(systemName: "arrow.up.forward.square")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                            .buttonStyle(.plain)
                            .help("在默认浏览器打开商品购买页")
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let error = monitor.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red).padding(8)
                }
            }
        }
    }

    private var statusText: String {
        if monitor.isRefreshing { return "正在更新四家店铺…" }
        guard let date = monitor.lastUpdated else { return "等待刷新" }
        let available = monitor.products.filter(\.inStock).count
        return "更新于 \(date.formatted(date: .omitted, time: .shortened)) · \(available) 件有货"
    }
}

private struct ProductGroup: Identifiable {
    let title: String
    let products: [Product]
    var id: String { title }
}
