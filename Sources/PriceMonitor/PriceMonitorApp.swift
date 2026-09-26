import SwiftUI
import AppKit

extension Notification.Name {
    static let showMonitorWindow = Notification.Name("showMonitorWindow")
}

@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    let monitor = PriceMonitor()
    let rightAPIMonitor = RightAPIUsageMonitor()
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    weak var mainWindow: NSWindow?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 启动时只作为菜单栏工具常驻，Dock 不显示图标。
        NSApp.setActivationPolicy(.accessory)
        // 登录自启用 -background 安静启动；用户手动打开（桌面/Dock）则直接显示窗口。
        DispatchQueue.main.async { [weak self] in
            if CommandLine.arguments.contains("-background") {
                self?.hideMainWindow()
            } else {
                self?.showMainWindow()
            }
        }
        // SwiftUI 窗口创建晚于代理回调，稍等后重试一次，确保手动打开时窗口一定出现。
        if !CommandLine.arguments.contains("-background") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showMainWindow()
            }
        }
    }

    func hideMainWindow() {
        guard let window = mainWindow ?? NSApp.windows.first(where: { $0.identifier?.rawValue == "monitor" }) else { return }
        mainWindow = window
        window.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    /// 点击 Dock 图标或桌面图标时，把隐藏的窗口重新弹出来。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func showMainWindow() {
        if let window = mainWindow {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "monitor" }) {
            mainWindow = window
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            // SwiftUI 原生窗口尚未创建，通知菜单栏标签用 openWindow 创建。
            NotificationCenter.default.post(name: .showMonitorWindow, object: nil)
            // 窗口创建是异步的，稍后再补一次，确保前台模式和 Dock 图标正确出现。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showMainWindow()
            }
            return
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct PriceMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(environment.monitor)
                .environmentObject(environment.rightAPIMonitor)
        } label: {
            Image(systemName: environment.monitor.menuBarSymbol)
                .accessibilityLabel("价格监控")
                .onReceive(NotificationCenter.default.publisher(for: .showMonitorWindow)) { _ in
                    openWindow(id: "monitor")
                }
        }
        .menuBarExtraStyle(.menu)

        // SwiftUI 原生窗口，保留 macOS 26 液态玻璃外观。
        Window("价格监控", id: "monitor") {
            MonitorView()
                .environmentObject(environment.monitor)
                .environmentObject(environment.rightAPIMonitor)
                .frame(minWidth: 760, minHeight: 560)
        }
        .defaultSize(width: 860, height: 650)
    }
}

private struct MenuBarContent: View {
    @EnvironmentObject private var monitor: PriceMonitor
    @EnvironmentObject private var rightAPIMonitor: RightAPIUsageMonitor

    var body: some View {
        Text(rightAPIMonitor.menuBarDetail)
        Button(rightAPIMonitor.isRefreshing ? "余额更新中…" : "刷新余额") {
            rightAPIMonitor.refresh()
        }
        .disabled(rightAPIMonitor.isRefreshing)
        Divider()
        Button("显示价格监控") {
            // 等菜单收起后再弹出窗口，避免被菜单追踪状态压住。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AppDelegate.shared?.showMainWindow()
            }
        }
        Divider()
        Button("退出价格监控", role: .destructive) { NSApplication.shared.terminate(nil) }
    }
}
