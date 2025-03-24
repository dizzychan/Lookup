//
//  SourceView.swift
//  Lookup6
//
//  Created by Wangzhen Wu on 23/03/2025.
//
import SwiftUI
import SwiftData

struct SourceView: View {
    
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var errorMessage: String?
    @State private var searchResults: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter keyword", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button("Search") {
                    performSearch(query: searchQuery)
                }
                .disabled(searchQuery.isEmpty)
                
                if isSearching {
                    ProgressView("Searching...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { result in
                        Text(result)
                    }
                } else {
                    Text("No search results")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationTitle("Source")
        }
    }
    
    private func performSearch(query: String) {
        // 清空之前的结果和错误信息
        searchResults = []
        errorMessage = nil
        isSearching = true
        
        // 模拟网络搜索；此处用异步延迟代替实际网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 搜索结束
            self.isSearching = false
            
            // 根据 query 做一些简单“假搜索”，假设结果就是 "Result 1", "Result 2"...
            if query == "error" {
                // 如果 query 是 "error"，示例抛个错误
                self.errorMessage = "Something went wrong..."
            } else {
                // 否则就返回几条假数据
                self.searchResults = [
                    "\(query) - Result 1",
                    "\(query) - Result 2",
                    "\(query) - Result 3"
                ]
            }
        }
    }
}

