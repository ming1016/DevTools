import AppKit

protocol HighlightProvider {
    func highlight(_ text: String) -> NSAttributedString
}
