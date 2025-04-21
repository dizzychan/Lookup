import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import SwiftSoup

struct ImportView: View {
    @Environment(\.modelContext) private var context

    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                }

                Button("Import File") {
                    isImporting = true
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.plainText, .pdf, .epub, .item],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let selectedFile = urls.first else { return }
                        handleFile(at: selectedFile)
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .navigationTitle("Import")
        }
    }

    private func handleFile(at url: URL) {
        do {
            let ext = url.pathExtension.lowercased()
            let bookTitle = url.deletingPathExtension().lastPathComponent

            switch ext {
            case "txt":
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                importTxtAsChapters(bookTitle: bookTitle, fullText: fileContent)

            case "pdf", "epub", "docx":
                // 非 txt，直接存 Book，走常规 copy + insert
                let type: BookFileType = BookFileType(rawValue: ext) ?? .unknown
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(
                    title: bookTitle,
                    content: "",
                    isPinned: false,
                    fileType: type,
                    fileURL: newURL.path
                )
                context.insert(newBook)

            default:
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(
                    title: bookTitle,
                    content: "",
                    isPinned: false,
                    fileType: .unknown,
                    fileURL: newURL.path
                )
                context.insert(newBook)
            }

            try context.save()
            print("Save success after handling file.")
        } catch {
            errorMessage = error.localizedDescription
            print("handleFile error: \(error)")
        }
    }

    /// 分章节导入 txt 文件
    private func importTxtAsChapters(bookTitle: String, fullText: String) {
        // 检测是否有章节关键词
        if !fullText.lowercased().contains("chapter ") {
            // 没有则直接存成一整本
            let newBook = Book(
                title: bookTitle,
                content: fullText,
                isPinned: false,
                fileType: .txt,
                fileURL: nil
            )
            context.insert(newBook)
            return
        }

        // 创建空 Book 以插入章节
        let newBook = Book(
            title: bookTitle,
            content: "",
            isPinned: false,
            fileType: .txt,
            fileURL: nil
        )
        context.insert(newBook)

        // HTML 解析分章
        guard
            let doc = try? SwiftSoup.parse(fullText),
            let bodytextDiv = try? doc.select("div.bodytext").first(),
            let elements = try? bodytextDiv.select("h3.chapter, h4.event, p.narrative").array()
        else {
            // 解析失败时 fallback
            newBook.content = fullText
            return
        }

        var chapterIndex = 0
        var currentTitle = "Introduction"
        var currentContent = ""

        func saveCurrentChapter() {
            guard !currentContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                currentContent = ""
                return
            }
            chapterIndex += 1
            let chap = Chapter(
                index: chapterIndex,
                title: currentTitle,
                content: currentContent,
                book: newBook
            )
            context.insert(chap)
            newBook.chapters.append(chap)  // ★ 关键：维护到 Book.chapters
            currentContent = ""
        }

        for el in elements {
            let tag = el.tagName()
            if tag == "h3", (try? el.hasClass("chapter")) == true {
                // 遇到新章节
                saveCurrentChapter()
                currentTitle = (try? el.text()) ?? "Chapter \(chapterIndex+1)"
            }
            else if tag == "h4", (try? el.hasClass("event")) == true {
                let text = (try? el.text()) ?? ""
                currentContent += text + "\n\n"
            }
            else if tag == "p", (try? el.hasClass("narrative")) == true {
                let text = (try? el.text()) ?? ""
                currentContent += text + "\n\n"
            }
        }
        // 保存最后一章
        saveCurrentChapter()
    }

    private func copyFileToDocuments(originalURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = docsURL.appendingPathComponent(originalURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: originalURL, to: destinationURL)
        return destinationURL
    }
}

