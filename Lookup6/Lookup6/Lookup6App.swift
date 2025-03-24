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
    @AppStorage("isDarkMode") private var isDarkMode = false
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Book.self)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
