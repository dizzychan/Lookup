//
//  SourceView.swift
//  LookUp
//
//  Created by Wangzhen Wu on 17/03/2025.
//
import SwiftUI
import SwiftData

struct SourceView: View {
    @State private var queryText: String = ""
    @State private var searchResults: [Book] = []
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search by Title or Author", text: $queryText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Search") {
                    // 这里仅用假数据演示
                    searchResults = [
                        Book(title: "Online Book 1", author: "Net Author"),
                        Book(title: "Online Book 2", author: "API Author")
                    ]
                }
            }
            .padding()
            
            List(searchResults) { book in
                HStack {
                    Text(book.title)
                    Spacer()
                    Button("Add to Bookshelf") {
                        context.insert(book)
                        do {
                            try context.save()
                        } catch {
                            print("Error saving new book: \(error)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Online Library")
    }
}

