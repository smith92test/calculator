import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    var window: FloatingWindow?
    private var viewModel: ViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        // .regular：在程序坞和 ⌘Tab 切换器中显示，行为与系统 Calculator 一致
        NSApp.setActivationPolicy(.regular)

        let vm = ViewModel()
        viewModel = vm

        let hostingView = NSHostingView(rootView: ContentView(viewModel: vm))
        window = FloatingWindow(
            contentView: hostingView,
            opacity: vm.opacity,
            isAlwaysOnTop: vm.isAlwaysOnTop
        )
        applyAlwaysOnTop()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        setupMainMenu()
    }

    // MARK: - 点击程序坞图标时重新显示窗口

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            applyAlwaysOnTop()
            window?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    // MARK: - 主菜单（启用 ⌘C/⌘V/⌘X/⌘Z 等快捷键）

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // ── App 菜单 ──
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "退出 Cal",
                                   action: #selector(NSApplication.terminate(_:)),
                                   keyEquivalent: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        // ── Edit 菜单 ── 接通剪贴板快捷键
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo",       action: Selector(("undo:")),              keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo",       action: Selector(("redo:")),              keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut",        action: #selector(NSText.cut(_:)),        keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy",       action: #selector(NSText.copy(_:)),       keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste",      action: #selector(NSText.paste(_:)),      keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)),  keyEquivalent: "a"))
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - 置顶

    /// 根据 viewModel.isAlwaysOnTop 设置窗口层级
    func applyAlwaysOnTop() {
        guard let win = window, let vm = viewModel else { return }
        win.level = vm.isAlwaysOnTop
            ? NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
            : .normal
    }
}
