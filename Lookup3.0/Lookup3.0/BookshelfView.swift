//
//  BookshelfView.swift
//  Lookup3.0
//
//  Created by Wangzhen Wu on 21/03/2025.
//
import SwiftUI
import SwiftData

struct BookshelfView: View {
    @Environment(\.modelContext) private var context // SwiftData 上下文
    @Query var books: [Book] // 从数据库查询所有书籍
    
    let columns = [GridItem(.adaptive(minimum: 150))] // 自适应列数
    
    var body: some View {
        NavigationStack {
            VStack {
                if books.isEmpty {
                    // 无书时显示提示
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No books yet!")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(books) { book in
                                VStack {
                                    // 书籍卡片
                                    NavigationLink {
                                        ReaderView(book: book)
                                    } label: {
                                        VStack {
                                            Image(systemName: "book.closed.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 80, height: 120)
                                                .foregroundColor(.blue)
                                            
                                            Text(book.title)
                                                .font(.caption)
                                                .lineLimit(1)
                                            
                                            HStack {
                                                ProgressView(value: book.progress)
                                                    .frame(width: 80)
                                                Text("\(Int(book.progress * 100))%")
                                                    .font(.caption2)
                                            }
                                            .padding(.horizontal)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                       }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Bookshelf")
        }
    }
}

