//
//  FileManager.swift
//  DevTools
//
//  Created by Ming on 2024/11/14.
//

@preconcurrency import SwiftUI
import AppKit

@Observable @MainActor final class FileSystemManager {
    static let shared = FileSystemManager()
    
    var selectedURL: URL?
    
    var fileTree: FileItem?
    var selectedFileURL: URL?
    var fileContent: String = ""
    
    var swiftFunctions = [FunctionInfo]()
    var hasSwiftFuncs: Bool = false
    
    private var swiftFuncsURL: URL? {
        devToolsURL?.appendingPathComponent("swiftFuncs")
    }
    
    enum ProcessingState {
        case idle
        case processing
        case completed
    }
    
    var processingState: ProcessingState = .idle
    
    private var devToolsURL: URL? {
        selectedURL?.appendingPathComponent(".devtools")
    }
    
    func resetSelectedFolder() {
        selectedURL = nil
        selectedFileURL = nil
        fileTree = nil
        fileContent = ""
    }
    
    func loadFileTree() {
        guard let url = selectedURL else { return }
        fileTree = createFileTree(url: url)
        checkSwiftFuncs()
    }
    
    private func createFileTree(url: URL) -> FileItem {
        let fileManager = Foundation.FileManager.default
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            print("文件不存在：\(url.path)")
            return FileItem(url: url, isDirectory: false, children: nil)
        }
        
        if isDirectory.boolValue {
            do {
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
                let children = contents.map { createFileTree(url: $0) }
                return FileItem(url: url, isDirectory: true, children: children)
            } catch {
                print("读取目录失败：\(error.localizedDescription)")
                return FileItem(url: url, isDirectory: true, children: [])
            }
        } else {
            return FileItem(url: url, isDirectory: false, children: nil)
        }
    }
    
    func loadFileContent(url: URL) async throws {
        selectedFileURL = url
        fileContent = try String(contentsOf: url, encoding: .utf8)
    }
    
    func saveFileContent() async throws {
        guard let url = selectedFileURL else { return }
        try fileContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    @Sendable
    func selectFolder() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedURL = url
                loadFileTree()
                print("Selected folder URL: \(selectedURL?.path ?? "")")
            }
        }
    }
    
    @Sendable
    func handleDrop(providers: [NSItemProvider]) async -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                if let item = try? await provider.loadItem(forTypeIdentifier: "public.file-url", options: nil),
                   let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    selectedURL = url
                    loadFileTree()
                    print("Dropped folder URL: \(selectedURL?.path ?? "")")
                    return true
                }
            }
        }
        return false
    }
    
    @Sendable
    func processSwiftFiles() async {
        processingState = .processing
        guard let url = selectedURL else { return }
        
        // 确保 .devtools 文件夹存在
        if let devToolsURL = devToolsURL {
            do {
                try FileManager.default.createDirectory(at: devToolsURL, withIntermediateDirectories: true)
            } catch {
                print("创建.devtools文件夹失败：\(error.localizedDescription)")
            }
        }
        
        await SwiftFileProcessor.processSwiftFiles(in: url, devToolsURL: devToolsURL)
        processingState = .completed
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            processingState = .idle
        }
    }
    
    func checkSwiftFuncs() {
        if let url = swiftFuncsURL,
           FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                swiftFunctions = try decoder.decode([FunctionInfo].self, from: data)
                hasSwiftFuncs = !swiftFunctions.isEmpty
            } catch {
                print("读取或解码swiftFuncs失败：\(error.localizedDescription)")
                hasSwiftFuncs = false
            }
        } else {
            hasSwiftFuncs = false
        }
    }
}


