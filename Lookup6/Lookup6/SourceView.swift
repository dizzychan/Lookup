import SwiftUI
import SwiftData
import SwiftSoup

/// 简易搜索结果结构体
struct SearchResult: Identifiable {
    let id: String
    let title: String
    let author: String
    let detailURL: String
}

struct SourceView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            VStack {
                // 搜索输入框
                HStack {
                    TextField("Enter keyword", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)

                    Button("Search") {
                        Task {
                            await doSearch()
                        }
                    }
                }
                .padding()

                if isLoading {
                    ProgressView("Searching...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if searchResults.isEmpty {
                    Text("No results")
                        .foregroundColor(.secondary)
                } else {
                    // 列表展示结果
                    List(searchResults) { result in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(result.title)
                                    .font(.headline)
                                Text(result.author)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            // 点击 Import
                            Button("Import") {
                                Task {
                                    await importDetailPage(for: result)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Source")
        }
    }

    /// 第一次搜索: 只获取列表(书名/作者/链接)
    private func doSearch() async {
        guard !searchQuery.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        searchResults = []

        do {
            let encoded = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://www.gutenberg.org/ebooks/search/?query=\(encoded)"
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            let doc = try SwiftSoup.parse(html)

            let elements = try doc.select("li.booklink")
            var tempResults: [SearchResult] = []

            for element in elements {
                let title = try element.select("span.title").text()
                let author = try element.select("span.subtitle").text()
                let linkHref = try element.select("a.link").attr("href")
                let uniqueID = linkHref.isEmpty ? UUID().uuidString : linkHref

                let result = SearchResult(
                    id: uniqueID,
                    title: title,
                    author: author,
                    detailURL: linkHref
                )
                tempResults.append(result)
            }
            self.searchResults = tempResults

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Import: 抓取详情页 & 分章节插入
    private func importDetailPage(for result: SearchResult) async {
        let baseURL = "https://www.gutenberg.org"
        let detailURLString = baseURL + result.detailURL

        guard let url = URL(string: detailURLString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            let doc = try SwiftSoup.parse(html)

            // 1) 先创建 Book
            let newBook = Book(title: result.title, fileType: .txt)
            context.insert(newBook)

            // 2) 查找元素: h3.chapter, p.narrative
            //    假设 <h3 class="chapter"> 表示新章起点,
            //    <p class="narrative"> 表示本章段落
            let chapterElements = try doc.select("div.bodytext h3.chapter, div.bodytext h4.event, div.bodytext p.narrative")

            var chapters: [Chapter] = []
            var currentChapterIndex = 1
            var currentChapterTitle = "Unknown Chapter"
            var currentText = ""

            for elem in chapterElements.array() {
                let tagName = try elem.tagName()

                if tagName == "h3" {
                    // 遇到新的章节标题 -> 存储上个章节(若有)
                    if !currentText.isEmpty {
                        let ch = Chapter(index: currentChapterIndex,
                                         title: currentChapterTitle,
                                         content: currentText,
                                         book: newBook)
                        context.insert(ch)
                        chapters.append(ch)

                        currentChapterIndex += 1
                        currentText = ""
                    }
                    // 更新当前章节标题
                    currentChapterTitle = try elem.text()

                } else if tagName == "p" {
                    // 段落正文 -> 追加到 currentText
                    let paragraph = try elem.text()
                    currentText += paragraph + "\n\n"
                }
            }

            // 循环结束后，如果还有剩余章节内容
            if !currentText.isEmpty {
                let ch = Chapter(index: currentChapterIndex,
                                 title: currentChapterTitle,
                                 content: currentText,
                                 book: newBook)
                context.insert(ch)
                chapters.append(ch)
            }

            // 3) 保存
            try context.save()

            print("Import success: Book=\(newBook.title), Chapters=\(chapters.count)")
        } catch {
            print("Error fetching detail page: \(error.localizedDescription)")
        }
    }
}

