import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    var children: [FileItem]?
    
    var name: String {
        url.lastPathComponent
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
