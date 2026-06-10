import Foundation
import Observation
import JavaScriptCore

struct HistoryEntry: Identifiable {
    let id = UUID()
    let expr: String
    let result: String
}

@Observable
final class ViewModel {
    var expression: String = "" {
        didSet {
            // 自动将中文括号 / 运算符转为 ASCII
            let cleaned = Self.normalize(expression)
            if cleaned != expression {
                expression = cleaned   // 触发第二次 didSet，后续走 evaluate()
                return
            }
            evaluate()
        }
    }

    /// 中文字符 → ASCII 等价符号
    private static func normalize(_ s: String) -> String {
        let map: [(Character, Character)] = [
            ("（", "("), ("）", ")"),
            ("【", "("), ("】", ")"),
            ("×", "*"), ("✕", "*"), ("✖", "*"),
            ("÷", "/"),
            ("＋", "+"),
            ("－", "-"), ("—", "-"), ("−", "-"),
            ("。", "."), ("．", "."),
            // 全角数字
            ("０","0"),("１","1"),("２","2"),("３","3"),("４","4"),
            ("５","5"),("６","6"),("７","7"),("８","8"),("９","9"),
        ]
        var chars = Array(s)
        for (from, to) in map {
            for i in chars.indices where chars[i] == from { chars[i] = to }
        }
        return String(chars)
    }
    var result: String = ""
    var history: [HistoryEntry] = []

    // MARK: - 持久化设置

    var opacity: Double = 0.95 {
        didSet { UserDefaults.standard.set(opacity, forKey: "CalOpacity") }
    }
    var isAlwaysOnTop: Bool = true {
        didSet { UserDefaults.standard.set(isAlwaysOnTop, forKey: "CalAlwaysOnTop") }
    }

    private let js = JSContext()!

    init() {
        // 从 UserDefaults 恢复设置（init 内赋值不触发 didSet，避免重复写入）
        let saved = UserDefaults.standard.double(forKey: "CalOpacity")
        if saved >= 0.3 { opacity = saved }

        if UserDefaults.standard.object(forKey: "CalAlwaysOnTop") != nil {
            isAlwaysOnTop = UserDefaults.standard.bool(forKey: "CalAlwaysOnTop")
        }
    }

    // MARK: - 实时求值

    private func evaluate() {
        let raw = expression.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { result = ""; return }

        // 只允许合法的算术字符，防止执行任意脚本
        let allowed = CharacterSet.decimalDigits
            .union(CharacterSet(charactersIn: "+-*/.() "))
        guard raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            result = ""; return
        }

        js.exceptionHandler = { _, _ in }
        guard let jsVal = js.evaluateScript(raw), jsVal.isNumber else {
            result = ""; return
        }

        let v = jsVal.toDouble()
        guard !v.isNaN, !v.isInfinite else { result = "错误"; return }

        // 整数结果不显示小数点
        if v == v.rounded(.towardZero) && abs(v) < 1e15 {
            result = String(Int(v))
        } else {
            result = String(format: "%.10g", v)
        }
    }

    // MARK: - 回车记录历史

    func commitToHistory() {
        let expr = expression.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty, !result.isEmpty, result != "错误" else { return }

        history.insert(HistoryEntry(expr: expr, result: result), at: 0)
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        expression = result   // 回车后把结果填回输入框，方便继续计算
    }

    func clearExpression() {
        expression = ""
    }

    // MARK: - 历史管理

    func delete(_ entry: HistoryEntry) {
        history.removeAll { $0.id == entry.id }
    }

    func clearHistory() {
        history.removeAll()
    }
}
