import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
                    allowedContentTypes: [
                        .plainText,  // txt 文件
                        .pdf,
                        .epub,
                        .item
                    ],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let selectedFile = urls.first else { return }
                        handleFile(at: selectedFile)
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
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
                // 如果是 txt 文件，我们演示把它按章节拆分
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                importTxtAsChapters(bookTitle: bookTitle, fullText: fileContent)
                
            case "pdf":
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .pdf,
                                   fileURL: newURL.path)
                context.insert(newBook)
                
            case "epub":
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .epub,
                                   fileURL: newURL.path)
                context.insert(newBook)
                
            case "docx":
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .docx,
                                   fileURL: newURL.path)
                context.insert(newBook)
                
            default:
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle,
                                   fileType: .unknown,
                                   fileURL: newURL.path)
                context.insert(newBook)
            }
            
            // 保存
            try context.save()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// 演示：把大的 txt 内容拆分为多个 Chapter
    private func importTxtAsChapters(bookTitle: String, fullText: String) {
        // 如果文本不含 "CHAPTER "，直接当作一整段写进 book.content
        if !fullText.contains("CHAPTER ") {
            let newBook = Book(
                title: bookTitle,
                content: fullText,  // 直接存全文
                fileType: .txt
            )
            context.insert(newBook)

            do {
                try context.save()
                print("Import: No 'CHAPTER ' found. Stored entire text in newBook.content. length=\(fullText.count)")
            } catch {
                print("Import Error (fallback single-chapter) -> \(error)")
            }
            return
        }

        // ===== 以下是包含 "CHAPTER " 的分章逻辑 =====
        print("Import: Found 'CHAPTER ' in text, proceeding to split...")

        // 先创建一个空 content 的 Book
        let newBook = Book(
            title: bookTitle,
            content: "",
            fileType: .txt
        )
        context.insert(newBook)

        let splits = fullText.components(separatedBy: "CHAPTER ")
        var chapterIndex = 1
        var hadAnyValidChapter = false

        for part in splits {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // 构造章节标题
            let chapterTitle = "Chapter \(chapterIndex)"
            chapterIndex += 1
            hadAnyValidChapter = true

            let chapter = Chapter(
                index: chapterIndex,
                title: chapterTitle,
                content: trimmed,
                book: newBook
            )
            context.insert(chapter)
        }

        // 如果没有拆出任何章节，就把全文塞进 book.content
        if !hadAnyValidChapter {
            newBook.content = fullText
            print("Import: 'CHAPTER ' found but no valid chapter? Fallback to book.content.")
        }

        do {
            try context.save()
            print("Import: Multi-chapter save success. hadAnyValidChapter=\(hadAnyValidChapter)")
        } catch {
            print("Import Error (multi-chapter) -> \(error)")
        }
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

