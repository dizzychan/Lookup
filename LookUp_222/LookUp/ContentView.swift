//
//  ContentView.swift
//  LookUp
//
//  Created by Wangzhen Wu on 17/03/2025.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            BookshelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical.fill")
                }
            
            ImportView()
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            
            SourceView()
                .tabItem {
                    Label("Sources", systemImage: "globe")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

