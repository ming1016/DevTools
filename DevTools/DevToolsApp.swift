//
//  DevToolsApp.swift
//  DevTools
//
//  Created by Ming on 2024/11/14.
//

import SwiftUI

@main
struct DevToolsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class TimeTrackerFunctionCost {
    private var startTime: Date?
    nonisolated(unsafe) static var functionCosts: [String : FunctionCost] = [String: FunctionCost]()
    
    func start() {
        startTime = Date()
    }
    
    func stop(functionName: String, file:String) {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime) * 1000
        let elapsedTimeString = String(format: "%.2f", elapsedTime)
        print("Function:\(functionName) executed:\(elapsedTimeString) ms")
        
        let fileName = file.components(separatedBy: "/").last ?? file
        
        if var functionCost = TimeTrackerFunctionCost.functionCosts[functionName] {
            functionCost.costTotalTime += elapsedTime
            functionCost.times += 1
            TimeTrackerFunctionCost.functionCosts[functionName] = functionCost
        } else {
            Task { @MainActor in
                TimeTrackerFunctionCost.functionCosts[functionName] = FunctionCost(costTotalTime: elapsedTime, times: 1, file: fileName)
            }
            
        }
    }

    struct FunctionCost {
        var costTotalTime: Double = 0 // 每次函数执行的总时间
        var times: Int = 0 // 函数执行次数
        var file: String = ""
    }
    
    func printFunctionCosts() {
        let costSortedByAverage = TimeTrackerFunctionCost.functionCosts.sorted {
            $0.value.costTotalTime / Double($0.value.times) > $1.value.costTotalTime / Double($1.value.times)
        }
        for (funcName, cost) in costSortedByAverage {
            let total = String(format: "%.2f", cost.costTotalTime)
            let times = cost.times
            let average = String(format: "%.2f", cost.costTotalTime / Double(cost.times))
            print("ave:\(average) ms times:\(times) total:\(total) ms func:\(funcName)")
        }
    }
    
    func printFunctions() {
        for (funcName, cost) in TimeTrackerFunctionCost.functionCosts {
            print("\(funcName) \(cost.file)")
        }
    }
}
