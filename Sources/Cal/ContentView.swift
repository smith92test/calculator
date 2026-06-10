import SwiftUI
import AppKit

// MARK: - 毛玻璃背景（NSVisualEffectView 包装）

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - 主界面

struct ContentView: View {
    @Bindable var viewModel: ViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            // 毛玻璃底层
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 0) {
                inputArea

                Divider().padding(.horizontal, 16)

                // 历史区（空状态 / 列表）均填满剩余高度
                if viewModel.history.isEmpty {
                    emptyHint
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.history) { entry in
                                HistoryRow(entry: entry) {
                                    viewModel.delete(entry)
                                } onTap: {
                                    viewModel.expression = entry.expr
                                    focused = true
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)

                    Divider().padding(.horizontal, 16)

                    Button("清空历史") { viewModel.clearHistory() }
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .buttonStyle(.plain)
                        .padding(.vertical, 7)
                }

                Divider().padding(.horizontal, 16)

                settingsRow
            }
        }
        // 跟随窗口尺寸自适应，不再固定 280×380
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { focused = true }
        // 透明度变化 → 实时更新窗口
        .onChange(of: viewModel.opacity) { _, v in
            AppDelegate.shared?.window?.alphaValue = v
        }
        // 置顶开关变化 → 实时更新窗口层级
        .onChange(of: viewModel.isAlwaysOnTop) { _, _ in
            AppDelegate.shared?.applyAlwaysOnTop()
        }
        // ⌘W 隐藏窗口
        .onKeyPress(.init("w"), phases: .down) { press in
            if press.modifiers.contains(.command) {
                NSApp.keyWindow?.orderOut(nil)
                return .handled
            }
            return .ignored
        }
    }

    // MARK: 输入区

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                TextField("0", text: $viewModel.expression)
                    .font(.system(size: 22, weight: .light, design: .monospaced))
                    .textFieldStyle(.plain)
                    .foregroundStyle(.primary)
                    .focused($focused)
                    .onSubmit { viewModel.commitToHistory() }

                // 清空按钮：有内容时显示
                if !viewModel.expression.isEmpty {
                    Button { viewModel.clearExpression(); focused = true } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            // 实时结果
            HStack(spacing: 4) {
                if !viewModel.result.isEmpty {
                    Text("=")
                        .foregroundStyle(.secondary)
                    Text(viewModel.result)
                        .foregroundStyle(viewModel.result == "错误" ? .red : .secondary)
                }
                Spacer()
            }
            .font(.system(size: 14, weight: .light, design: .monospaced))
            .frame(height: 18)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: 空历史提示

    private var emptyHint: some View {
        Text("↩  回车记录历史")
            .font(.system(size: 12))
            .foregroundStyle(.quaternary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: 设置行（透明度 + 置顶开关）

    private var settingsRow: some View {
        HStack(spacing: 8) {

            // 置顶开关：pin.fill（蓝色）= 置顶中；pin（灰色）= 未置顶
            Button {
                viewModel.isAlwaysOnTop.toggle()
            } label: {
                Image(systemName: viewModel.isAlwaysOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundStyle(
                        viewModel.isAlwaysOnTop ? Color.accentColor : Color.secondary.opacity(0.5)
                    )
                    .frame(width: 18)
            }
            .buttonStyle(.plain)
            .help(viewModel.isAlwaysOnTop ? "取消置顶" : "始终置顶")

            // 透明度滑块
            Image(systemName: "sun.min")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)

            Slider(value: $viewModel.opacity, in: 0.3...1.0, step: 0.05)
                .controlSize(.mini)

            Image(systemName: "sun.max")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)

            // 可调整大小的视觉提示（拖拽窗口边缘可改变大小）
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 9))
                .foregroundStyle(.quaternary)
                .help("拖拽窗口边缘可调整大小")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}

// MARK: - 历史条目行

struct HistoryRow: View {
    let entry: HistoryEntry
    let onDelete: () -> Void
    let onTap: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 6) {
            Text(entry.expr)
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundStyle(.primary)
            Text("=")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(entry.result)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary)

            Spacer()

            if hovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .background(hovered ? Color.primary.opacity(0.05) : Color.clear)
        .onHover { hovered = $0 }
        .onTapGesture { onTap() }
    }
}
