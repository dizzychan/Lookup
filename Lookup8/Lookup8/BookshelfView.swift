//
//  BookshelfView.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import SwiftUI
import SwiftData

struct BookShelfView: View {
    // 1）查询出所有 Book 实例
    @Query private var allBooks: [Book]
    @Environment(\.modelContext) private var context

    // 2）先置顶的排在前面，再按 title 升序
    private var sortedBooks: [Book] {
        allBooks.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.title < rhs.title
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedBooks.isEmpty {
                    // 书架为空时的占位
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Books Yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)]) {
                            ForEach(sortedBooks) { book in
                                // 3）点击进入对应的阅读器
                                NavigationLink(destination: destination(for: book)) {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconName(for: book))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 80)
                                            .foregroundColor(.accentColor)
                                        Text(book.title)
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                                .contextMenu {
                                  // —— 安全删除 ——
                                  Button(role: .destructive) {
                                    Task {
                                      await MainActor.run {
                                        // 1. 先删掉所有关联的章节
                                        for chapter in book.chapters {
                                          context.delete(chapter)
                                        }
                                        // 2. 然后再删掉书本身
                                        context.delete(book)
                                        // 3. 最后保存
                                        try? context.save()
                                      }
                                    }
                                  } label: {
                                    Label("Delete", systemImage: "trash")
                                  }

                                    // —— 安全置顶/取消置顶 ——
                                    Button {
                                        Task {
                                            await MainActor.run {
                                                book.isPinned.toggle()
                                                try? context.save()
                                            }
                                        }
                                    } label: {
                                        Label(book.isPinned ? "Unpin" : "Pin to Top",
                                              systemImage: "pin")
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

    /// 根据文件类型和有没有章节，决定跳转到哪个阅读器
    @ViewBuilder
    private func destination(for book: Book) -> some View {
        switch book.fileType {
        case .txt:
            // 有章节则用分章阅读器，否则用纯文本阅读器
            if !book.chapters.isEmpty {
                BookReaderView(book: book)
            } else {
                ReaderView(book: book)
            }
        case .pdf:
            PDFReaderView(filePath: book.fileURL ?? "")
        case .epub, .docx, .unknown:
            QuickLookView(filePath: book.fileURL ?? "")
        }
    }

    /// 根据不同文件类型展示不同图标
    private func iconName(for book: Book) -> String {
        switch book.fileType {
        case .txt:     return "doc.text"
        case .pdf:     return "doc.richtext"
        case .epub:    return "book"
        case .docx:    return "doc"
        case .unknown: return "questionmark.folder"
        }
    }
}

