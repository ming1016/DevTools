import SwiftUI

struct FolderSelectionView: View {
    @State private var fileManager = FileSystemManager.shared
    @State private var isTargeted = false
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 20) {
                // 左侧区域
               VStack(alignment: .leading, spacing: 20) {
                   Button(action: {
                       Task {
                           await fileManager.selectFolder()
                       }
                   }) {
                       VStack {
                           Image(systemName: "folder.badge.plus")
                               .font(.system(size: 40))
                           Text("选择文件夹")
                       }
                   }
                   .buttonStyle(.borderless)
                   
                   Spacer()
               }
               .frame(width: 200)
                
                // 右侧拖拽区域
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                            
                            .frame(minWidth: 400, minHeight: 300)
                        
                        VStack {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 40))
                            Text("将文件夹拖拽到这里")
                                .font(.title3)
                        }
                    }
                    .foregroundColor(isTargeted ? .blue : .gray)
                }
                .onDrop(of: [.fileURL], isTargeted: .init(get: { isTargeted },
                                                         set: { isTargeted = $0 })) { providers in
                    Task {
                        return await fileManager.handleDrop(providers: providers)
                    }
                    return false
                }
            }
            .padding()
        }
    }
}
