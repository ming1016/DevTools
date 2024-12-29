import AppKit

final class XMLHighlightProvider: HighlightProvider {
    func highlight(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        // 设置基本字体
        attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular), range: range)
        
        // 高亮标签
        highlightPattern("<[^>]+>", in: attributedString, color: .systemBlue)
        
        // 高亮属性名
        highlightPattern("\\b\\w+(?=\\s*=)", in: attributedString, color: .systemPink)
        
        // 高亮属性值
        highlightPattern("\"[^\"]*\"", in: attributedString, color: .systemGreen)
        
        // 高亮注释
        highlightPattern("<!--[\\s\\S]*?-->", in: attributedString, color: .systemGray)
        
        return attributedString
    }
}
