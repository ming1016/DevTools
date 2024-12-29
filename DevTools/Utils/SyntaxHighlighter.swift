import Foundation
import AppKit

@MainActor
final class SyntaxHighlighter: @unchecked Sendable {
    static let shared = SyntaxHighlighter()
    
    enum FileType {
        case swift
        case markdown
        case xml
        case unknown
        
        static func from(url: URL?) -> FileType {
            guard let fileExtension = url?.pathExtension.lowercased() else { return .unknown }
            switch fileExtension {
            case "swift": return .swift
            case "md": return .markdown
            case "plist", "entitlements", "storyboard", "xib", "xml", "xcscheme", "xcworkspacedata": return .xml
            default: return .unknown
            }
        }
    }
    
    private let providers: [FileType: HighlightProvider]
    
    private init() {
        self.providers = [
            .swift: SwiftHighlightProvider(),
            .markdown: MarkdownHighlightProvider(),
            .xml: XMLHighlightProvider()
        ]
    }
    
    func highlightCode(_ text: String, fileType: FileType = .swift) -> NSAttributedString {
        if let provider = providers[fileType] {
            return provider.highlight(text)
        }
        return NSAttributedString(string: text)
    }
}

// 工具方法扩展
extension HighlightProvider {
    func highlightPattern(_ pattern: String, in attributedString: NSMutableAttributedString, color: NSColor) {
        highlightPattern(pattern, in: attributedString) { str, range in
            str.addAttribute(.foregroundColor, value: color, range: range)
        }
    }
    
    func highlightPattern(_ pattern: String, in attributedString: NSMutableAttributedString, handler: (NSMutableAttributedString, NSRange) -> Void) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        let range = NSRange(location: 0, length: attributedString.length)
        let matches = regex.matches(in: attributedString.string, options: [], range: range)
        
        for match in matches.reversed() {
            handler(attributedString, match.range)
        }
    }
}


