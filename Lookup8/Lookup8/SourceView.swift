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
    let coverURL: URL?
}

struct SourceView: View {
    @Environment(\.modelContext) private var context
    private let networkManager = NetworkManager.shared

    @State private var query = ""
    @State private var results: [SourceItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchSource: SearchSource = .network
    @State private var importingItemId: UUID? = nil

    /// 导入完成后要跳转的书
    @State private var importedBook: Book?
    /// 控制导航跳转
    @State private var showReader = false

    enum SearchSource: String, CaseIterable {
        case local = "Local"
        case network = "Network"
    }

    var body: some View {
        NavigationStack {
            VStack {
                // 来源选择
//                Picker("Source", selection: $searchSource) {
//                    ForEach(SearchSource.allCases, id: \.self) { source in
//                        Text(source.rawValue).tag(source)
//                    }
//                }
//                .padding(.horizontal)
//                .pickerStyle(.segmented)
//                .onChange(of: searchSource) { _, _ in
//                    results = []
//                    query = ""
//                }

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
//                .padding(.horizontal)
//                .padding(.top,5)

                // 错误提示
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // 加载指示器
                if isLoading {
                    ProgressView("Searching...")
                        .padding()
                }

                // 搜索结果列表
                List(results) { item in
                    HStack {
                        if let coverURL = item.coverURL {
                            AsyncImage(url: coverURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 70)
                            .cornerRadius(4)
                        } else {
                            Image(systemName: "book.closed")
                                .frame(width: 50, height: 70)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            Task { await importRemote(item) }
                        } label: {
                            ZStack {
                                if importingItemId == item.id {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Import")
                                }
                            }
                            .frame(width: 60)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(importingItemId == item.id)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .overlay {
                    if results.isEmpty && !isLoading {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try searching for something else")
                        )
                    }
                }
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

    private func performSearch() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        switch searchSource {
        case .network:
            do {
                let items = try await networkManager.searchBooks(query: query)
                await MainActor.run {
                    results = items
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
        case .local:
            // 本地搜索逻辑
            let fetchDescriptor = FetchDescriptor<Book>(
                predicate: #Predicate<Book> { book in
                    book.title.localizedStandardContains(query)
                }
            )
            
            do {
                let localBooks = try context.fetch(fetchDescriptor)
                await MainActor.run {
                    results = localBooks.map { book in
                        SourceItem(
                            title: book.title,
                            author: "Local Book",
                            detailURL: URL(string: "local://\(book.id)")!,
                            coverURL: nil
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: — 下载 + 分章导入 —
    private func importRemote(_ item: SourceItem) async {
        errorMessage = nil
        await MainActor.run { importingItemId = item.id }
        do {
            print("start fetching content...")
            let content = try await networkManager.fetchBookContent(url: item.detailURL)
            
            // Download cover image if available
            var coverImageData: Data? = nil
            if let coverURL = item.coverURL {
                do {
                    let (data, _) = try await URLSession.shared.data(from: coverURL)
                    coverImageData = data
                } catch {
                    print("Failed to download cover image: \(error)")
                }
            }
            
            await MainActor.run {
                let book = importTxtOrHTML(title: item.title, fullText: content as! String)
                book.coverImage = coverImageData
                do {
                    try context.save()
                    importedBook = book
                    showReader = true
                } catch {
                    errorMessage = error.localizedDescription
                }
                importingItemId = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                importingItemId = nil
            }
        }
    }

    /// title: 书名；fullText: 原始 HTML/纯文本
    private func importTxtOrHTML(title: String, fullText: String) -> Book {
        // 判断是否为 HTML 内容
        if fullText.contains("<html") || fullText.contains("<HTML") {
            return importHTMLAsChapters(title: title, content: fullText)
        } else {
            return importTxtAsChapters(title: title, content: fullText)
        }
    }

    // MARK: — HTML 分章逻辑 —
    private func importHTMLAsChapters(title: String, content fullText: String) -> Book {
        // Create a new book
        let book = Book(
            title: title,
            content: "",
            isPinned: false,
            fileType: .txt,
            fileURL: nil
        )
        context.insert(book)

        do {
            // Parse HTML using SwiftSoup with minimal processing
            let doc = try SwiftSoup.parse(fullText, "", Parser.xmlParser())
            
            // Find all chapter divs or sections
            let chapterElements = try doc.select("div.chapter, section.chapter")
            
            // If no chapter elements found, treat the whole content as one chapter
            if chapterElements.isEmpty() {
                // Extract only the main content, excluding headers and footers
                let mainContent = try doc.select("body").first()?.text() ?? ""
                let chapter = Chapter(
                    index: 1,
                    title: "Chapter 1",
                    content: mainContent,
                    book: book
                )
                context.insert(chapter)
                book.chapters.append(chapter)
                return book
            }
            
            // Process chapters in batches to avoid memory issues
            let batchSize = 5
            let totalChapters = chapterElements.count
            var processedChapters = 0
            
            while processedChapters < totalChapters {
                let endIndex = min(processedChapters + batchSize, totalChapters)
                let batch = Array(chapterElements[processedChapters..<endIndex])
                
                for (index, chapterElement) in batch.enumerated() {
                    let chapterIndex = processedChapters + index + 1
                    
                    // Get chapter title (try h2, h1, or use default)
                    let title = try chapterElement.select("h2, h1").first()?.text() ?? "Chapter \(chapterIndex)"
                    
                    // Get chapter content, excluding headers and footers
                    let content = try chapterElement.text()
                    
                    // Create and add chapter
                    let chapter = Chapter(
                        index: chapterIndex,
                        title: title,
                        content: content,
                        book: book
                    )
                    context.insert(chapter)
                    book.chapters.append(chapter)
                    
                    // Update loading progress
                    Task { @MainActor in
                        let progress = Double(chapterIndex) / Double(totalChapters)
                        print("Processing chapter \(chapterIndex) of \(totalChapters) (Progress: \(Int(progress * 100))%)")
                    }
                }
                
                processedChapters = endIndex
            }
        } catch {
            print("Error parsing HTML: \(error)")
            // If parsing fails, fall back to treating the whole content as one chapter
            let chapter = Chapter(
                index: 1,
                title: "Chapter 1",
                content: fullText,
                book: book
            )
            context.insert(chapter)
            book.chapters.append(chapter)
        }
        
        
        return book
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

        // 简单地按行扫描，一旦遇到全大写且包含"CHAPTER"的行，就做新章节
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

