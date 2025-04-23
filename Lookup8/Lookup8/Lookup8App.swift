//
//  Lookup6App.swift
//  Lookup6
//
//  Created by Wangzhen Wu on 23/03/2025.
//

import SwiftUI
import SwiftData

@main
struct Lookup8App: App {
    // 暗黑模式开关
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 一次性把所有用到的 Model 注册进去：
                .modelContainer(
                    for: [
                        Book.self,
                        Chapter.self,
                        Item.self
                    ]
                )
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

