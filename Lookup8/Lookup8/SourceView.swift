//
//  SourceView.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import SwiftUI
import SwiftData
import SwiftSoup

/// 搜索结果模型
struct SourceItem: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let detailURL: URL
}

struct SourceView: View {
    @Environment(\.modelContext) private var context

    @State private var query = ""
    @State private var results: [SourceItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    /// 导入完成后要跳转的书
    @State private var importedBook: Book?
    /// 控制导航跳转
    @State private var showReader = false

    var body: some View {
        NavigationStack {
            VStack {
                // 搜索框
                HStack {
                    TextField("Search term", text: $query)
                        .textFieldStyle(.roundedBorder)
                    Button("Search") {
                        Task { await performSearch() }
                    }
                    .disabled(isLoading || query.isEmpty)
                }
                .padding()

                // 错误提示
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // 搜索结果列表
                List(results) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Import") {
                            Task { await importRemote(item) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Source")
            // 隐形跳转 Link 用 overlay，避免拦截列表点击
            .overlay {
                NavigationLink(isActive: $showReader) {
                    if let book = importedBook {
                        BookReaderView(book: book)
                    } else {
                        EmptyView()
                    }
                } label: {
                    EmptyView()
                }
                .frame(width: 0, height: 0)
                .hidden()
            }
        }
    }

    // MARK: — 模拟搜索 (改成 TXT 链接) —
    private func performSearch() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(nanoseconds: 300_000_000)

        results = [
            SourceItem(
                title: "Frankenstein",
                author: "Mary Shelley",
                // 直接用 TXT 链接
                detailURL: URL(string: "https://www.gutenberg.org/files/84/84-0.txt")!
            ),
            SourceItem(
                title: "Pride and Prejudice",
                author: "Jane Austen",
                detailURL: URL(string: "https://www.gutenberg.org/files/1342/1342-0.txt")!
            )
        ]
    }

    // MARK: — 下载 + 分章导入 —
    private func importRemote(_ item: SourceItem) async {
        errorMessage = nil
        do {
            let (data, _) = try await URLSession.shared.data(from: item.detailURL)
            guard let text = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }

            await MainActor.run {
                let book = importTxtAsChapters(title: item.title, content: text)
                do {
                    try context.save()
                    // 导入成功后跳转
                    importedBook = book
                    showReader = true
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    // MARK: — 分章逻辑，返回新建的 Book —
    private func importTxtAsChapters(title: String, content fullText: String) -> Book {
        // 如果没有明显的 chapter 关键词，就当单章
        if !fullText.lowercased().contains("chapter") {
            let b = Book(
                title: title,
                content: fullText,
                isPinned: false,
                fileType: .txt,
                fileURL: nil
            )
            context.insert(b)
            return b
        }

        // 建一个空 Book
        let book = Book(
            title: title,
            content: "",
            isPinned: false,
            fileType: .txt,
            fileURL: nil
        )
        context.insert(book)

        // 将全文拆行，方便分段处理
        let lines = fullText.components(separatedBy: .newlines)
        var idx = 0
        var curTitle = "Introduction"
        var curText = ""

        func saveChapter() {
            let text = curText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            idx += 1
            let chap = Chapter(
                index: idx,
                title: curTitle,
                content: text,
                book: book
            )
            context.insert(chap)
            book.chapters.append(chap)
            curText = ""
        }

        // 简单地按行扫描，一旦遇到全大写且包含“CHAPTER”的行，就做新章节
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.uppercased().hasPrefix("CHAPTER") {
                // 分隔新章
                saveChapter()
                curTitle = t
            } else {
                // 普通段落累积
                curText += t + "\n"
            }
        }
        saveChapter()
        return book
    }
}

