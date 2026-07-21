import SwiftUI

@main
struct PriceMonitorApp: App {
    @StateObject private var monitor = PriceMonitor()
    @StateObject private var woyaoMonitor = WoyaoUsageMonitor()

    var body: some Scene {
        MenuBarExtra(woyaoMonitor.menuBarTitle, systemImage: "creditcard") {
            MenuBarContent()
                .environmentObject(monitor)
                .environmentObject(woyaoMonitor)
        }
        .menuBarExtraStyle(.menu)

        Window("价格监控", id: "monitor") {
            MonitorView()
                .environmentObject(monitor)
                .environmentObject(woyaoMonitor)
                .frame(minWidth: 760, minHeight: 560)
        }
        .defaultSize(width: 860, height: 650)
    }
}

private struct MenuBarContent: View {
    @EnvironmentObject private var monitor: PriceMonitor
    @EnvironmentObject private var woyaoMonitor: WoyaoUsageMonitor
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(woyaoMonitor.menuBarDetail)
        Button(woyaoMonitor.isRefreshing ? "余额更新中…" : "刷新余额") { woyaoMonitor.refresh() }
            .disabled(woyaoMonitor.isRefreshing)
        Divider()
        Button("显示价格监控") { openWindow(id: "monitor") }
        Divider()
        Button("退出价格监控", role: .destructive) { NSApplication.shared.terminate(nil) }
    }
}
