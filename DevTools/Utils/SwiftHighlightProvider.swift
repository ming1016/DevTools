import AppKit

final class SwiftHighlightProvider: HighlightProvider {
    private let keywords = ["class", "struct", "enum", "func", "var", "let", "if", "else", "guard", "return", "import"]
    private let types = ["String", "Int", "Double", "Bool", "Array", "Dictionary"]
    
    func highlight(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        // 设置基本字体
        attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), range: range)
        
        // 高亮关键字
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            highlightPattern(pattern, in: attributedString, color: .systemPink)
        }
        
        // 高亮类型
        for type in types {
            let pattern = "\\b\(type)\\b"
            highlightPattern(pattern, in: attributedString, color: .systemGreen)
        }
        
        // 高亮字符串
        highlightPattern("\".*?\"", in: attributedString, color: .systemRed)
        
        // 高亮注释
        highlightPattern("//.*$", in: attributedString, color: .systemGray)
        
        return attributedString
    }
}
