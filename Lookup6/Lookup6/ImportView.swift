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
                        self.errorMessage = error.localizedDescription
                        print("File importer error: \(error.localizedDescription)")
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
            print("Handling file: \(bookTitle), ext: \(ext)")
            
            switch ext {
            case "txt":
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                print("Read txt file content length: \(fileContent.count)")
                importTxtAsChapters(bookTitle: bookTitle, fullText: fileContent)
                
            case "pdf":
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle, fileType: .pdf, fileURL: newURL.path)
                context.insert(newBook)
                print("Imported pdf file, stored at: \(newURL.path)")
                
            case "epub":
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle, fileType: .epub, fileURL: newURL.path)
                context.insert(newBook)
                print("Imported epub file, stored at: \(newURL.path)")
                
            case "docx":
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle, fileType: .docx, fileURL: newURL.path)
                context.insert(newBook)
                print("Imported docx file, stored at: \(newURL.path)")
                
            default:
                let newURL = try copyFileToDocuments(originalURL: url)
                let newBook = Book(title: bookTitle, fileType: .unknown, fileURL: newURL.path)
                context.insert(newBook)
                print("Imported unknown file type, stored at: \(newURL.path)")
            }
            
            try context.save()
            print("Save success after handling file.")
        } catch {
            self.errorMessage = error.localizedDescription
            print("handleFile error: \(error.localizedDescription)")
        }
    }
    
    /// 分章节导入 txt 文件
    /// 如果文本中不含 "chapter "（不区分大小写），则直接将全文存入 Book.content；否则，解析 HTML 结构，按章节拆分存入 Chapter 模型。
    private func importTxtAsChapters(bookTitle: String, fullText: String) {
        print("Importing txt file: \(bookTitle), fullText length: \(fullText.count)")
        if !fullText.lowercased().contains("chapter ") {
            let newBook = Book(title: bookTitle, content: fullText, fileType: .txt)
            context.insert(newBook)
            do {
                try context.save()
                print("Import: No 'chapter ' found. Stored entire text. Length=\(fullText.count)")
            } catch {
                print("Import Error (fallback single-chapter): \(error.localizedDescription)")
            }
            return
        }
        
        print("Import: Found 'chapter ' in text, proceeding to split into chapters using HTML parsing...")
        guard let doc = try? SwiftSoup.parse(fullText) else {
            print("Error: Failed to parse fullText as HTML. Fallback to storing entire text.")
            let newBook = Book(title: bookTitle, content: fullText, fileType: .txt)
            context.insert(newBook)
            do {
                try context.save()
            } catch {
                print("Fallback save error: \(error.localizedDescription)")
            }
            return
        }
        
        importHtmlAsChapters(from: doc, bookTitle: bookTitle)
    }
    
    /// 使用 HTML DOM 结构拆分章节，并存入 SwiftData 的 Chapter 模型
    private func importHtmlAsChapters(from doc: Document, bookTitle: String) {
        // 创建新的 Book，章节存储时 Book.content 为空
        let newBook = Book(title: bookTitle, content: "", fileType: .txt)
        context.insert(newBook)
        
        // 尝试获取正文容器
        guard let bodytextDiv = try? doc.select("div.bodytext").first() else {
            print("No div.bodytext found. Fallback: storing entire text in Book.content.")
            if let plainText = try? doc.text() {
                newBook.content = plainText
            }
            do {
                try context.save()
            } catch {
                print("Save error in fallback: \(error.localizedDescription)")
            }
            return
        }
        
        // 选择正文中所有相关元素，按出现顺序排列
        guard let elements = try? bodytextDiv.select("h3.chapter, h4.event, p.narrative").array() else {
            print("Failed to select chapter elements.")
            newBook.content = (try? doc.text()) ?? ""
            do {
                try context.save()
            } catch {
                print("Save error in fallback: \(error.localizedDescription)")
            }
            return
        }
        
        var currentChapterTitle: String = "Introduction"
        var currentChapterContent: String = ""
        var chapterIndex = 0
        
        for element in elements {
            let tag = element.tagName()
            if tag == "h3", (try? element.hasClass("chapter")) == true {
                // 如果已有章节内容，则保存上一章
                if !currentChapterContent.isEmpty {
                    chapterIndex += 1
                    let chapter = Chapter(index: chapterIndex,
                                          title: currentChapterTitle,
                                          content: currentChapterContent,
                                          book: newBook)
                    context.insert(chapter)
                    newBook.chapters.append(chapter)  // 追加到 Book 的 chapters 数组
                    print("Inserted chapter \(chapterIndex): \(currentChapterTitle), content length: \(currentChapterContent.count)")
                    currentChapterContent = ""
                }
                currentChapterTitle = (try? element.text()) ?? "Unknown Chapter"
            } else if tag == "h4", (try? element.hasClass("event")) == true {
                let eventText = (try? element.text()) ?? ""
                currentChapterContent += eventText + "\n\n"
            } else if tag == "p", (try? element.hasClass("narrative")) == true {
                let para = (try? element.text()) ?? ""
                currentChapterContent += para + "\n\n"
            }
        }
        
        // 保存最后剩余的章节内容
        if !currentChapterContent.isEmpty {
            chapterIndex += 1
            let chapter = Chapter(index: chapterIndex,
                                  title: currentChapterTitle,
                                  content: currentChapterContent,
                                  book: newBook)
            context.insert(chapter)
            newBook.chapters.append(chapter)
            print("Inserted final chapter \(chapterIndex): \(currentChapterTitle), content length: \(currentChapterContent.count)")
        }
        
        do {
            try context.save()
            print("Import success: Book=\(newBook.title), Chapters=\(chapterIndex)")
        } catch {
            print("Error saving chapters: \(error.localizedDescription)")
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

