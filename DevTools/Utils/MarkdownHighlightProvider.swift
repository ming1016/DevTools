import AppKit

final class MarkdownHighlightProvider: HighlightProvider {
    func highlight(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        // 基本设置
        attributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 12), range: range)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        
        // 标题 (h1 - h6)
        for i in 1...6 {
            let fontSize = 24 - (i * 2) // h1: 22, h2: 20, h3: 18, etc.
            highlightPattern("^#{" + String(i) + "}\\s+.*$", in: attributedString) { str, range in
                str.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: CGFloat(fontSize)), range: range)
            }
        }
        
        // 无序列表（支持 -, *, + 三种符号）
        highlightPattern("^\\s*[-*+]\\s+.*$", in: attributedString) { str, range in
            let style = NSMutableParagraphStyle()
            style.headIndent = 20
            style.firstLineHeadIndent = 20
            str.addAttribute(.paragraphStyle, value: style, range: range)
            // 突出显示列表符号
            if let regex = try? NSRegularExpression(pattern: "[-*+]\\s+"),
               let match = regex.firstMatch(in: str.string, range: range) {
                str.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
            }
        }
        
        // 有序列表（支持数字后跟点号）
        highlightPattern("^\\s*\\d+\\.\\s+.*$", in: attributedString) { str, range in
            let style = NSMutableParagraphStyle()
            style.headIndent = 25
            style.firstLineHeadIndent = 20
            str.addAttribute(.paragraphStyle, value: style, range: range)
            // 突出显示数字和点号
            if let regex = try? NSRegularExpression(pattern: "\\d+\\.\\s+"),
               let match = regex.firstMatch(in: str.string, range: range) {
                str.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
            }
        }
        
        // 粗体
        highlightPattern("\\*\\*(.+?)\\*\\*|__(.+?)__", in: attributedString) { str, range in
            str.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 12), range: range)
        }
        
        // 斜体
        highlightPattern("\\*(.+?)\\*|_(.+?)_", in: attributedString) { str, range in
            str.addAttribute(.font, value: NSFont.systemFont(ofSize: 12, weight: .light), range: range)
            str.addAttribute(.obliqueness, value: 0.2, range: range)
        }
        
        // 行内代码
        highlightPattern("`[^`]+`", in: attributedString) { str, range in
            str.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), range: range)
            str.addAttribute(.backgroundColor, value: NSColor.tertiarySystemFill, range: range)
            str.addAttribute(.foregroundColor, value: NSColor.systemRed, range: range)
        }
        
        // 链接
        highlightPattern("\\[([^\\]]+)\\]\\(([^\\)]+)\\)", in: attributedString) { str, range in
            str.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
            str.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        
        // 图片
        highlightPattern("!\\[([^\\]]+)\\]\\(([^\\)]+)\\)", in: attributedString) { str, range in
            str.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: range)
            // 可选：为图片标记添加特殊字体
            str.addAttribute(.font, value: NSFont.systemFont(ofSize: 12, weight: .medium), range: range)
        }
        
        // 引用块
        highlightPattern("^\\s*>\\s+.*$", in: attributedString) { str, range in
            // 设置缩进样式
            let style = NSMutableParagraphStyle()
            style.headIndent = 20
            style.firstLineHeadIndent = 20
            str.addAttribute(.paragraphStyle, value: style, range: range)
            
            // 设置文本颜色为绿色
            str.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: range)
            
            // 突出显示引用符号 >
            if let regex = try? NSRegularExpression(pattern: ">\\s+"),
               let match = regex.firstMatch(in: str.string, range: range) {
                str.addAttribute(.foregroundColor, value: NSColor.systemGreen.withAlphaComponent(0.7), range: match.range)
            }
        }
        
        return attributedString
    }
}
