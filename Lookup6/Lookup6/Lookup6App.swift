//
//  Lookup6App.swift
//  Lookup6
//
//  Created by Wangzhen Wu on 23/03/2025.
//

import SwiftUI
import SwiftData

@main
struct Lookup6App: App {
    // 暗黑模式开关
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 一次性把你用到的所有 Model 都注册进来
                .modelContainer(for: [
                    Book.self,
                    Chapter.self,
                    Bookmark.self,
                    Item.self   // 如果你还有 Item 之类的实体，就放这里
                ])
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
