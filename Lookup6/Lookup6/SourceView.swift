// SourceView.swift
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

    var body: some View {
        NavigationStack {
            VStack {
                // — 搜索框 —
                HStack {
                    TextField("Search term", text: $query)
                        .textFieldStyle(.roundedBorder)
                    Button("Search") {
                        Task { await performSearch() }
                    }
                }
                .padding()

                // — 错误提示 —
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }

                // — 列表 & 导入按钮 —
                List(results) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text(item.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Import") {
                            Task { await importRemote(item) }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Source")
        }
    }

    // MARK: — 搜索（模拟） —
    private func performSearch() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 300_000_000)
        results = [
            SourceItem(
                title: "The Red Room",
                author: "H. G. Wells",
                detailURL: URL(string: "https://www.gutenberg.org/files/252/252-h/252-h.htm")!
            ),
            SourceItem(
                title: "The Country of the Blind",
                author: "H. G. Wells",
                detailURL: URL(string: "https://www.gutenberg.org/files/3012/3012-h/3012-h.htm")!
            )
        ]
    }

    // MARK: — 远程下载 + 分章导入 —
    private func importRemote(_ item: SourceItem) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: item.detailURL)
            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }

            await MainActor.run {
                // 执行分章逻辑
                importTxtAsChapters(bookTitle: item.title, fullText: html)
                // 保存
                do {
                    try context.save()
                    print("✅ Imported '\(item.title)'")
                } catch {
                    print("❌ Save error:", error)
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            print("❌ Download/import error:", error)
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    // 如果全文没有 chapter 标记，就作为一本无章节的 txt 存入
    private func importTxtAsChapters(bookTitle: String, fullText: String) {
        if !fullText.lowercased().contains("chapter ") {
            let b = Book(title: bookTitle, content: fullText, isPinned: false, fileType: .txt, fileURL: nil)
            context.insert(b)
            return
        }
        // 否则尝试当 HTML 解析
        guard let doc = try? SwiftSoup.parse(fullText) else {
            let b = Book(title: bookTitle, content: fullText, isPinned: false, fileType: .txt, fileURL: nil)
            context.insert(b)
            return
        }
        importHtmlAsChapters(from: doc, bookTitle: bookTitle)
    }

    private func importHtmlAsChapters(from doc: SwiftSoup.Document, bookTitle: String) {
        // 先新建一本空 Book
        let newBook = Book(title: bookTitle, content: "", isPinned: false, fileType: .txt, fileURL: nil)
        context.insert(newBook)

        // 找到正文容器
        guard let bodyDiv = try? doc.select("div.bodytext").first(),
              let els = try? bodyDiv.select("h3.chapter, h4.event, p.narrative").array()
        else {
            // 回退：把纯文本放到 content
            newBook.content = (try? doc.text()) ?? ""
            return
        }

        var idx = 0
        var curTitle = "Introduction"
        var curText = ""

        func saveChapter() {
            // 只保存非空章节
            let trimmed = curText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            idx += 1
            let chap = Chapter(index: idx, title: curTitle, content: curText, book: newBook)
            context.insert(chap)
            newBook.chapters.append(chap)
            curText = ""
        }

        for el in els {
            let tag = el.tagName()
            if tag == "h3", (try? el.hasClass("chapter")) == true {
                // 遇到新章标题，先保存上一章
                saveChapter()
                // 再读取新章标题
                if let t = try? el.text() {
                    curTitle = t
                }
            }
            else if tag == "h4", (try? el.hasClass("event")) == true {
                // 事件标题也算内容的一部分
                if let t = try? el.text() {
                    curText += t + "\n\n"
                }
            }
            else if tag == "p", (try? el.hasClass("narrative")) == true {
                // 正文段落
                if let t = try? el.text() {
                    curText += t + "\n\n"
                }
            }
        }
        // 循环结束后保存最后一章
        saveChapter()
    }
}

