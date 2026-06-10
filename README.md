# Cal — 浮层计算器

macOS 原生浮层计算器，随时悬浮在桌面上。

![截图](cal-app.png)

## 功能

- 实时求值，边输入边显示结果
- 回车记录历史，点击历史可回填
- 置顶开关 — 浮在所有窗口上方
- 透明度调节
- 窗口大小/位置自动记忆
- 自动将中文括号、运算符转为 ASCII（`（）× ÷` 等）
- 支持复制粘贴（⌘C / ⌘V）
- 显示在程序坞，⌘W 隐藏，点坞栏图标重新打开

## 安装

### 方式一：下载编译好的 App（推荐）

1. 前往 [Releases](../../releases/latest) 下载最新的 `Cal-vX.X.zip`
2. 解压，将 `Cal.app` 拖入 `/Applications`
3. **首次打开** 需在终端执行一次（绕过 Gatekeeper）：
   ```bash
   xattr -cr /Applications/Cal.app
   ```
   之后正常双击即可。

### 方式二：从源码编译

**要求：** macOS 14+，Xcode Command Line Tools

```bash
git clone https://github.com/YOUR_USERNAME/cal.git
cd cal
bash build-app.sh
cp -r Cal.app /Applications/
```

## 系统要求

- macOS 14 (Sonoma) 或更高版本

## 开发

```bash
swift build          # 调试构建
swift run            # 直接运行
bash build-app.sh    # 打包成 .app
```

## 许可证

MIT
