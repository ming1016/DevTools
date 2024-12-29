import Foundation
import AppKit

struct SwiftFileProcessor {
    
    // 添加用于标识跟踪代码的常量
    private static let trackerMarker = "// Starming DevTools Function Tracker"
    
    static func processSwiftFiles(in directory: URL, devToolsURL: URL?) async {
        let fileManager = Foundation.FileManager.default
        let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil)
        var functionInfos: [FunctionInfo] = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "swift" {
                if let foundFunctions = await processSwiftFile(at: fileURL) {
                    functionInfos.append(contentsOf: foundFunctions)
                }
            }
        }
        
        // 保存函数信息
        if let devToolsURL = devToolsURL {
            let swiftFuncsURL = devToolsURL.appendingPathComponent("swiftFuncs")
            
            // 检查文件是否已存在
            if !FileManager.default.fileExists(atPath: swiftFuncsURL.path) {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(functionInfos)
                    try data.write(to: swiftFuncsURL)
                    print("已保存函数信息到: \(swiftFuncsURL.path)")
                } catch {
                    print("保存函数信息失败：\(error.localizedDescription)")
                }
            } else {
                print("swiftFuncs 文件已存在，跳过保存")
            }
        }
    }
    
    private static func processSwiftFile(at url: URL) async -> [FunctionInfo]? {
        var newContent = ""
        var hasMainAttribute = false
        var foundFunctions: [FunctionInfo] = []
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            // 如果文件已包含跟踪标记，跳过处理
            if content.contains(trackerMarker) {
                print("文件已包含跟踪代码：\(url.lastPathComponent)")
                return nil
            }
            
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            var insideBlockComment = false
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                if insideBlockComment {
                    if trimmedLine.contains("*/") {
                        insideBlockComment = false
                    }
                    newContent += line + "\n"
                    continue
                }
                
                if trimmedLine.hasPrefix("//") {
                    newContent += line + "\n"
                    continue
                }
                
                if trimmedLine.hasPrefix("/*") {
                    insideBlockComment = true
                    newContent += line + "\n"
                    continue
                }
                
                if trimmedLine.contains("@main") {
                    hasMainAttribute = true
                }
                
                if isFunctionDeclaration(line: trimmedLine) {
                    let functionName = extractFunctionName(from: trimmedLine)
                    let fileName = url.lastPathComponent
                    foundFunctions.append(FunctionInfo(
                        functionName: functionName,
                        filePath: url.path(percentEncoded: true)
                    ))
                    
                    // 添加标记注释
                    newContent += "\(trackerMarker)\n"
                    newContent += line + "\n"
                    newContent += "let tracker = TimeTrackerFunctionCost()\n"
                    newContent += "tracker.start()\n"
                    newContent += "defer { tracker.stop(functionName: \"\(functionName)\", file:\"\(fileName)\") }\n"
                    continue
                }
                
                newContent += line + "\n"
            }
            
            if hasMainAttribute {
                if let trackerCode = try? loadTimeTrackerCode() {
                    newContent += "\n\(trackerMarker)\n" + trackerCode
                }
            }
            
            try newContent.write(to: url, atomically: true, encoding: .utf8)
            return foundFunctions
            
        } catch {
            print("处理文件失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    private static func loadTimeTrackerCode() throws -> String? {
        guard let codeFileURL = Bundle.main.url(forResource: "TimeTrackerFunctionCostCode", withExtension: nil) else {
            print("未找到TimeTrackerFunctionCostCode资源文件")
            return nil
        }
        
        return try String(contentsOf: codeFileURL, encoding: .utf8)
    }
    
    private static func isFunctionDeclaration(line: String) -> Bool {
        let keywords = ["func ", "public func ", "private func ", "internal func ", "fileprivate func ", "@objc func ", "@IBAction func ", "@discardableResult func ","override func","static func"]
        if !isSwiftUIViewFunction(line: line) {
            return keywords.contains { line.hasPrefix($0) }
        } else {
            return false
        }
    }
    
    private static func extractFunctionName(from line: String) -> String {
        let components = line.split(separator: "(", maxSplits: 1)
        if components.count > 0 {
            let nameComponents = components[0].split(separator: " ")
            if let name = nameComponents.last {
                return String(name)
            }
        }
        return ""
    }
    
    private static func isSwiftUIViewFunction(line: String) -> Bool {
        return line.contains("-> some View") || line.contains("-> View")
    }
}


