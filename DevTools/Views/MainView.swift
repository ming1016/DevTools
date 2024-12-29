import SwiftUI

struct MainView: View {
    @State private var fileManager = FileSystemManager.shared
    @State private var showFunctionList = false
    
    var body: some View {
        HSplitView {
            FileTreeView(fileTree: fileManager.fileTree)
                .frame(minWidth: 200, maxWidth: 300)
            
            if showFunctionList {
                FunctionListView(functions: fileManager.swiftFunctions)
                    .frame(minWidth: 400)
            } else {
                FileEditorView(content: $fileManager.fileContent)
                    .frame(minWidth: 400)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    fileManager.resetSelectedFolder()
                }) {
                    Label("选择文件夹", systemImage: "folder.badge.minus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await fileManager.processSwiftFiles()
                    }
                }) {
                    Label(processingStateTitle, systemImage: processingStateIcon)
                }
                .disabled(fileManager.processingState == .processing)
            }
            
            if fileManager.hasSwiftFuncs {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showFunctionList.toggle()
                    }) {
                        Label(showFunctionList ? "隐藏函数列表" : "显示函数列表",
                              systemImage: showFunctionList ? "list.bullet.rectangle.portrait.fill" : "list.bullet.rectangle.portrait")
                        
                    }
                }
            }
        }
        .onAppear {
            fileManager.loadFileTree()
        }
    }
    
    private var processingStateTitle: String {
        switch fileManager.processingState {
        case .idle:
            return "处理 Swift 文件"
        case .processing:
            return "处理中..."
        case .completed:
            return "处理完成"
        }
    }
    
    private var processingStateIcon: String {
        switch fileManager.processingState {
        case .idle:
            return "gauge.with.dots.needle.33percent"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle"
        }
    }
}
