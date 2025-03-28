import SwiftUI
import SwiftData
import SwiftSoup

/// 简易搜索结果结构体
struct SearchResult: Identifiable {
    let id: String
    let title: String
    let author: String
}

struct SourceView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // 如果想把搜索到的书加入 SwiftData，可以获取 modelContext
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            VStack {
                // 搜索输入区域
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

                // 显示加载、错误、无结果提示，或结果列表
                if isLoading {
                    ProgressView("Searching...")
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                } else if searchResults.isEmpty {
                    Text("No results")
                        .foregroundColor(.secondary)
                } else {
                    // 有结果则显示列表
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
                            // 导入到 Bookshelf 的按钮
                            Button("Import") {
                                importToBookshelf(result)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Source")
        }
    }

    /// 进行搜索并解析网页HTML
    private func doSearch() async {
        guard !searchQuery.isEmpty else { return }

        // 重置状态
        isLoading = true
        errorMessage = nil
        searchResults = []

        do {
            // 1. 拼接搜索URL
            // 例如: https://www.gutenberg.org/ebooks/search/?query=alice
            let encoded = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://www.gutenberg.org/ebooks/search/?query=\(encoded)"
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }

            // 2. 获取网页内容
            let (data, _) = try await URLSession.shared.data(from: url)
            let html = String(decoding: data, as: UTF8.self)

            // 3. 使用 SwiftSoup 解析 HTML
            let doc = try SwiftSoup.parse(html)

            // 4. 找到每一个搜索结果列表项
            //   Gutenberg 搜索结果通常放在 <li class="booklink"> 中
            let elements = try doc.select("li.booklink")

            var tempResults: [SearchResult] = []
            for element in elements {
                // 书名在 <span class="title"> 中
                let title = try element.select("span.title").text()

                // 作者等信息在 <span class="subtitle"> 中
                let author = try element.select("span.subtitle").text()

                // 详情链接 <a class="link" href="/ebooks/12345">
                let linkHref = try element.select("a.link").attr("href")
                // 也可用 linkHref 做id 或者用 UUID
                let uniqueID = linkHref.isEmpty ? UUID().uuidString : linkHref

                let result = SearchResult(
                    id: uniqueID,
                    title: title,
                    author: author
                )
                tempResults.append(result)
            }
            self.searchResults = tempResults
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// 将搜索结果导入 SwiftData 的 Book (仅示例)
    private func importToBookshelf(_ result: SearchResult) {
        // 组装一个新的 Book
        let newBook = Book(
            title: result.title,
            content: "[可后续从详情页抓取文本]",
            fileType: .txt // 也可自定义
        )

        // 存入 SwiftData
        context.insert(newBook)
        do {
            try context.save()
        } catch {
            print("Failed to save new book: \(error)")
        }
    }
}

