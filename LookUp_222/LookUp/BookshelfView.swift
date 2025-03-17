import SwiftUI
import SwiftData

struct BookshelfView: View {
    @Environment(\.modelContext) private var context
    @Query var books: [Book]  // 自动获取 SwiftData 里的所有书籍
    
    let columns = [GridItem(.adaptive(minimum: 150))]

    var body: some View {
        NavigationStack {
            VStack {
                if books.isEmpty {
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
                            ForEach(books.sorted(by: { $0.pinned && !$1.pinned })) { book in
                                VStack {
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
                                // 📌 长按弹出菜单
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteBook(book)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        togglePin(book)
                                    } label: {
                                        Label(book.pinned ? "取消置顶" : "置顶", systemImage: book.pinned ? "pin.slash.fill" : "pin.fill")
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

    // 删除书籍
    private func deleteBook(_ book: Book) {
        context.delete(book)
        do {
            try context.save()
        } catch {
            print("Failed to delete book: \(error)")
        }
    }

    // 置顶/取消置顶
    private func togglePin(_ book: Book) {
        book.pinned.toggle()
        do {
            try context.save()
        } catch {
            print("Failed to update pin status: \(error)")
        }
    }
}
