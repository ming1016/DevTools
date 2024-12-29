//
//  ContentView.swift
//  DevTools
//
//  Created by Ming on 2024/11/14.
//

import SwiftUI

struct ContentView: View {
    @State private var fileManager = FileSystemManager.shared
    
    var body: some View {
        Group {
            if fileManager.selectedURL != nil {
                MainView()
            } else {
                FolderSelectionView()
            }
        }
    }
}



