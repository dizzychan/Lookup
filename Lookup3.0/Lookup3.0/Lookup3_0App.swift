//
//  Lookup3_0App.swift
//  Lookup3.0
//
//  Created by Wangzhen Wu on 21/03/2025.
//

import SwiftUI
import SwiftData

@main
struct Lookup3_0App: App {
    @AppStorage("darkMode") private var darkMode = false
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
                .preferredColorScheme(darkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
}
