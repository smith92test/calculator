#!/usr/bin/env bash
# release.sh — 本地打包并发布到 GitHub Release
set -euo pipefail

# ── 版本号（可作为参数传入，默认自动递增）──────────────────────────────
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    # 读取最新 tag，自动 +1
    LAST=$(git tag --sort=-v:refname | grep -E '^v[0-9]' | head -1 2>/dev/null || echo "v0.0")
    IFS='.' read -r MAJOR MINOR <<< "${LAST#v}"
    VERSION="v${MAJOR}.$((MINOR + 1))"
fi
echo "▶ 版本：$VERSION"

# ── 构建 .app ─────────────────────────────────────────────────────────
bash build-app.sh

# ── 打包成 zip ────────────────────────────────────────────────────────
ZIP="Cal-${VERSION}.zip"
rm -f "$ZIP"
# ditto 保留 macOS 扩展属性（比 zip 命令更兼容）
ditto -c -k --sequesterRsrc --keepParent Cal.app "$ZIP"
echo "▶ 已压缩：$ZIP（$(du -sh "$ZIP" | cut -f1)）"

# ── 打 git tag ────────────────────────────────────────────────────────
git tag "$VERSION"
git push origin "$VERSION"

# ── 发布到 GitHub Release ─────────────────────────────────────────────
gh release create "$VERSION" "$ZIP" \
    --title "Cal $VERSION" \
    --notes "## 安装方法

1. 下载 \`$ZIP\` 并解压
2. 将 \`Cal.app\` 拖入 \`/Applications\`
3. **首次打开** 需要绕过 Gatekeeper，终端执行一次：
   \`\`\`bash
   xattr -cr /Applications/Cal.app
   \`\`\`
   之后正常双击打开即可。

**系统要求：** macOS 14+"

echo ""
echo "✅ 发布完成！"
gh release view "$VERSION" --web   # 自动在浏览器打开 Release 页面
