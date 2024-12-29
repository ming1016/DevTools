//
//  FuntionInfo.swift
//  DevTools
//
//  Created by Ming Dai on 2024/11/18.
//

struct FunctionInfo: Codable, Identifiable {
    let functionName: String
    let filePath: String
    
    var id: String { functionName }
}
