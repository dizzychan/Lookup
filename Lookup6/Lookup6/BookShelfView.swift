import SwiftUI
import SwiftData

struct BookShelfView: View {
    // 获取所有书
    @Query var allBooks: [Book]
    
    @Environment(\.modelContext) private var context
    
    // 手动排序：先置顶的排前，再按 title 升序
    private var sortedBooks: [Book] {
        allBooks.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            } else {
                return lhs.title < rhs.title
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if sortedBooks.isEmpty {
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
                                // 删除操作
                                Button(role: .destructive) {
                                    withAnimation {
                                        context.delete(book)
                                        try? context.save()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                // 置顶/取消置顶
                                Button {
                                    withAnimation {
                                        book.isPinned.toggle()
                                        try? context.save()
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
                .navigationTitle("My Bookshelf")
            }
        }
    }
    
    // 根据书的文件类型选择目标阅读视图
    @ViewBuilder
    private func destination(for book: Book) -> some View {
        switch book.fileType {
        case .txt:
            // 如果章节数组非空，则认为是分章节导入，使用 BookReaderView；
            // 否则，使用 ReaderView 从 Book.content 读取文本
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
    
    // 根据文件类型返回合适的系统图标名称
    private func iconName(for book: Book) -> String {
        switch book.fileType {
        case .txt:
            return "doc.text"
        case .pdf:
            return "doc.richtext"
        case .epub:
            return "book"
        case .docx:
            return "doc"
        case .unknown:
            return "questionmark.folder"
        }
    }
}

