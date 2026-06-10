import AppKit

final class FloatingWindow: NSPanel {
    private static let originKey = "CalWindowOrigin"
    private static let sizeKey   = "CalWindowSize"

    init(contentView: NSView, opacity: Double, isAlwaysOnTop: Bool) {
        let size   = FloatingWindow.restoreSize() ?? CGSize(width: 280, height: 380)
        let origin = FloatingWindow.restoreOrigin()
        let rect   = CGRect(origin: origin ?? .zero, size: size)

        super.init(
            contentRect: rect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        level                     = isAlwaysOnTop
                                    ? NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
                                    : .normal
        isOpaque                  = false
        backgroundColor           = .clear
        hasShadow                 = true
        isMovableByWindowBackground = true
        hidesOnDeactivate         = false   // 切换到其他 App 时不自动隐藏
        alphaValue                = opacity
        // 在所有 Space 和全屏应用上方显示
        collectionBehavior        = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // 最小尺寸：输入区 + 设置行 + 边距
        minSize                   = NSSize(width: 220, height: 180)

        self.contentView = contentView
        delegate = self

        if origin == nil { center() }
    }

    // borderless panel 需要手动允许成为 key window
    override var canBecomeKey:  Bool { true }
    override var canBecomeMain: Bool { true }

    // 点击窗口时若不在最前，先拉到最前
    override func mouseDown(with event: NSEvent) {
        if !isKeyWindow {
            makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        super.mouseDown(with: event)
    }

    // MARK: - 恢复上次位置 / 大小

    private static func restoreOrigin() -> CGPoint? {
        guard let str = UserDefaults.standard.string(forKey: originKey) else { return nil }
        let pt = NSPointFromString(str)
        guard let screen = NSScreen.main,
              screen.visibleFrame.contains(pt) else { return nil }
        return pt
    }

    private static func restoreSize() -> CGSize? {
        guard let str = UserDefaults.standard.string(forKey: sizeKey) else { return nil }
        let sz = NSSizeFromString(str)
        guard sz.width >= 220, sz.height >= 180 else { return nil }
        return sz
    }
}

// MARK: - NSWindowDelegate：移动 / 调整大小时持久化

extension FloatingWindow: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromSize(frame.size),   forKey: FloatingWindow.sizeKey)
    }
    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromPoint(frame.origin), forKey: FloatingWindow.originKey)
    }
}
