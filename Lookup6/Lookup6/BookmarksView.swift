// BookmarksView.swift
import SwiftUI
import SwiftData

struct BookmarksView: View {
    // 取出所有 Bookmark
    @Query private var bookmarks: [Bookmark]
    // 取出所有 Book，用来显示书名
    @Query private var allBooks: [Book]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                ForEach(bookmarks) { bm in
                    // 找到对应书
                    if let book = allBooks.first(where: { $0.id == bm.bookId }) {
                        NavigationLink {
                            // 跳回阅读器，ReadingView 会根据 bm.pageIndex 自动定位
                            ReaderView(book: book)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)                   // 书名
                                    .font(.headline)
                                Text("Page \(bm.pageIndex + 1)")   // 页码（1-based）
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    // 支持滑动删除
                    for idx in offsets {
                        context.delete(bookmarks[idx])
                    }
                    try? context.save()
                }
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}

