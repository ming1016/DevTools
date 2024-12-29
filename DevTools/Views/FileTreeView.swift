import SwiftUI

struct FileTreeView: View {
    let fileTree: FileItem?
    @State private var fileManager = FileSystemManager.shared
    
    var body: some View {
        if let fileTree = fileTree {
            List(selection: $fileManager.selectedFileURL) {
                FileItemView(item: fileTree, level: 0)  // 从第0层开始
            }
            .frame(minWidth: 200)
        } else {
            Text("加载中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct FileItemView: View {
    let item: FileItem
    let level: Int  // 添加层级参数
    @State private var isExpanded: Bool
    
    init(item: FileItem, level: Int) {
        self.item = item
        self.level = level
        // 只有第0层的目录默认展开
        _isExpanded = State(initialValue: level == 0 && item.isDirectory)
    }
    
    private func iconForFile(_ filename: String) -> (name: String, color: Color) {
        if item.isDirectory {
            return ("folder.fill", .blue)
        }
        
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift":
            return ("swift", .orange)
        case "json", "xml", "yaml", "yml":
            return ("doc.text", .gray)
        case "md", "txt":
            return ("doc.text.fill", .gray)
        case "png", "jpg", "jpeg", "gif":
            return ("photo", .green)
        case "pdf":
            return ("doc.fill", .red)
        case "zip", "rar", "7z":
            return ("doc.zipper", .brown)
        default:
            return ("doc", .gray)
        }
    }
    
    var body: some View {
        if item.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                if let children = item.children {
                    ForEach(children.filter { $0.name != ".DS_Store" }) { child in
                        FileItemView(item: child, level: level + 1)  // 子项层级+1
                    }
                }
            } label: {
                let icon = iconForFile(item.name)
                HStack(spacing:3) {
                    Image(systemName: icon.name).foregroundStyle(icon.color)
                    Text(item.name)
                }
            }
        } else {
            let icon = iconForFile(item.name)
            HStack(spacing:3) {
                Image(systemName: icon.name).foregroundStyle(icon.color)
                Text(item.name)
            }
            .tag(item.url)
        }
    }
}
