import SwiftUI

struct FileEditorView: View {
    @Binding var content: String
    @State private var fileManager = FileSystemManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isModified = false
    @State private var undoManager: UndoManager?  // 添加回来
    
    var body: some View {
        CodeTextView(
            text: $content,
            isModified: $isModified,
            fileType: SyntaxHighlighter.FileType.from(url: fileManager.selectedFileURL),
            onSave: {
                saveFile()
            }
        )
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("保存") {
                        saveFile()
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!isModified)
                }
            }
            .onChange(of: fileManager.selectedFileURL) { oldValue, newValue in  // 更新为新的语法
                Task {
                    if let url = newValue {
                        do {
                            try await fileManager.loadFileContent(url: url)
                            isModified = false  // 重置修改状态
                        } catch {
                            showError("无法加载文件: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
    }
    
    private func saveFile() {
        guard let url = fileManager.selectedFileURL else { return }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            isModified = false  // 保存成功后重置修改状态
        } catch {
            showError("保存文件失败: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

