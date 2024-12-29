import SwiftUI

struct CodeTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isModified: Bool
    var fileType: SyntaxHighlighter.FileType
    var highlighter = SyntaxHighlighter.shared
    var onSave: () -> Void  // 添加保存回调
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // 配置文本视图
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.delegate = context.coordinator
        
        // 注册应用终止通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        // 设置背景色和文本容器
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        
        // 配置文本容器和布局
        let contentSize = scrollView.contentSize
        textView.minSize = NSSize(width: 0.0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        
        // 设置 TextContainer
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // 配置滚动视图
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.documentView = textView
        
        // 设置滚动视图的属性
        scrollView.borderType = .noBorder
        scrollView.horizontalScrollElasticity = .none
        scrollView.autohidesScrollers = true
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let attributedString = highlighter.highlightCode(text, fileType: fileType)
        
        if textView.string != text {
            textView.textStorage?.setAttributedString(attributedString)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeTextView
        private var originalContent: String = ""
        
        init(_ parent: CodeTextView) {
            self.parent = parent
            super.init()
        }
        
        @MainActor
        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            originalContent = textView.string
        }
        
        @MainActor
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.isModified = textView.string != originalContent
        }
        
        @MainActor
        func textDidEndEditing(_ notification: Notification) {
            if parent.isModified {
                parent.onSave()
            }
        }
        
        @objc @MainActor
        func applicationWillTerminate(_ notification: Notification) {
            if parent.isModified {
                parent.onSave()
            }
        }
    }
}
