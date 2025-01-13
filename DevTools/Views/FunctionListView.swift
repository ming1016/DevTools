import SwiftUI

struct ParsedFunction {
    let functionName: String
    let fileName: String
}

struct FunctionListView: View {
    let functions: [FunctionInfo]
    @State private var inputText: String = ""
    @State private var parsedFunctions: [ParsedFunction] = []
    @State private var sortOption = SortOption.original
    
    enum SortOption {
        case original
        case matched
        case unmatched
    }
    
    private func parseInputText() {
        // 首先规范化换行符，将 \r\n 和 \r 都转换为 \n
        let normalizedText = inputText.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        // 按换行符分割，同时过滤空行和处理前后空白
        let lines = normalizedText.split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        parsedFunctions = lines.compactMap { line in
            // 处理连续多个空格的情况，将其压缩为单个空格
            let cleanLine = line.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            let components = cleanLine.split(separator: " ", omittingEmptySubsequences: true)
            
            // 确保至少有函数名和文件名两个部分
            guard components.count >= 2 else { return nil }
            
            // 如果有多个部分，取第一个作为函数名，最后一个作为文件名
            return ParsedFunction(
                functionName: String(components[0]),
                fileName: String(components.last!)
            )
        }
    }
    
    private func isMatched(_ function: FunctionInfo) -> Bool {
        parsedFunctions.contains { parsed in
            parsed.functionName == function.functionName &&
            URL(fileURLWithPath: function.filePath).lastPathComponent == parsed.fileName
        }
    }
    
    private func sortedFunctions() -> [FunctionInfo] {
        switch sortOption {
        case .original:
            return functions
        case .matched:
            return functions.sorted { isMatched($0) && !isMatched($1) }
        case .unmatched:
            return functions.sorted { !isMatched($0) && isMatched($1) }
        }
    }
    
    var body: some View {
        VStack {
            TextEditor(text: $inputText)
                .frame(height: 100)
                .border(Color.gray)
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
            
            Button("Parse Input") {
                parseInputText()
            }
            
            Picker("Sort by", selection: $sortOption) {
                Text("Default").tag(SortOption.original)
                Text("Matched").tag(SortOption.matched)
                Text("UnMatched").tag(SortOption.unmatched)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            List(sortedFunctions()) { function in
                VStack(alignment: .leading) {
                    HStack {
                        Text(function.functionName)
                            .font(.headline)
                        if isMatched(function) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    let filePath = URL(fileURLWithPath: function.filePath).lastPathComponent
                    Text(filePath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
