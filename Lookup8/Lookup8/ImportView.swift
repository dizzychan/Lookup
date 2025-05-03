//
//  ImportView.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import SwiftSoup
import PDFKit
import ZIPFoundation
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var context
    @State private var isImporting = false
    @State private var errorMessage: String?
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                // 顶部插图
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemGray6))
                        .frame(width: 180, height: 220)
                        .shadow(radius: 4)
                    VStack {
                        Image(systemName: "arrow.down.doc.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        Spacer().frame(height: 16)
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 120, height: 8)
                            .cornerRadius(4)
                            .opacity(0.5)
                    }
                }
                // 标题
                Text("Import eBook")
                    .font(.title)
                    .fontWeight(.bold)
                // 说明
                Text("Choose a TXT, PDF, EPUB, or DOCX file to import into your library.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                // 错误提示
                if let err = errorMessage {
                    Text("Error: \(err)")
                        .foregroundColor(.red)
                }
                // 大按钮
                Button(action: { isImporting = true }) {
                    Text("IMPORT FILE")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [
                        .plainText, .pdf, .epub, UTType.html, .item
                    ],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        importFile(at: url)
                    case .failure(let err):
                        errorMessage = err.localizedDescription
                    }
                }
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Import")
        }
    }

    private func importFile(at url: URL) {
        do {
            let ext = url.pathExtension.lowercased()
            let title = url.deletingPathExtension().lastPathComponent

            switch ext {
            case "txt", "html", "htm":
                let text = try String(contentsOf: url, encoding: .utf8)
                importTxtOrHTML(title: title, fullText: text)

            case "pdf", "epub", "docx":
                let type = BookFileType(rawValue: ext) ?? .unknown
                let dest = try copyToDocuments(url)
                let book = Book(
                    title: title,
                    content: "",
                    isPinned: false,
                    fileType: type,
                    fileURL: dest.path
                )
                
                // Extract cover image based on file type
                if let coverData = extractCoverImage(from: dest, type: type) {
                    book.coverImage = coverData
                }
                
                context.insert(book)

            default:
                let dest = try copyToDocuments(url)
                let book = Book(
                    title: title,
                    content: "",
                    isPinned: false,
                    fileType: .unknown,
                    fileURL: dest.path
                )
                context.insert(book)
            }

            try context.save()
            print("✅ Import succeeded")
            selectedTab = 0  // Switch to bookshelf tab (index 0)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Import error:", error)
        }
    }

    /// —— 只保留一个"统一分章"函数 ——
    /// title: 书名；fullText: 原始 HTML/纯文本
    private func importTxtOrHTML(title: String, fullText: String) {
        // 1) 新建一本空 Book（暂不往 content 里写东西）
        let book = Book(
            title: title,
            content: "",
            isPinned: false,
            fileType: .txt,
            fileURL: nil
        )
        context.insert(book)

        // 2) 解析 HTML DOM
        guard let doc = try? SwiftSoup.parse(fullText) else {
            // 解析失败，直接把全文当一章
            book.content = fullText
            return
        }

        // 3) 找所有可能的"章节标题"节点
        let h3s = (try? doc.select("h3.chapter").array()) ?? []
        let allH2s = (try? doc.select("h2").array()) ?? []
        // 过滤 Gutenberg 那种 "CHAPTER 1."、"CHAPTER I" 之类
        let h2s = allH2s.filter { el in
            let raw = (try? el.text().trimmingCharacters(in: .whitespacesAndNewlines).uppercased()) ?? ""
            return raw.hasPrefix("CHAPTER")
        }

        // 全文段落
        let ps = (try? doc.select("p").array()) ?? []

        // 4) 合并并按在 HTML 里的顺序排序
        var els = h3s + h2s + ps
        els.sort { lhs, rhs in
            lhs.siblingIndex < rhs.siblingIndex
        }

        // 5) 如果一个章节标题也没找到，就回落全文单章
        guard els.contains(where: { $0.tagName().lowercased().hasPrefix("h") }) else {
            book.content = (try? doc.text()) ?? fullText
            return
        }

        // 6) 真正的分章流程：遇到标题就 new chapter，否则累加到正文
        var idx = 0
        var curTitle = "Introduction"
        var curText = ""

        func saveChapter() {
            let t = curText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else {
                curText = ""
                return
            }
            idx += 1
            let chap = Chapter(index: idx, title: curTitle, content: t, book: book)
            context.insert(chap)
            book.chapters.append(chap)
            curText = ""
        }

        for el in els {
            let tag = el.tagName().lowercased()
            if (tag == "h3" && (try? el.hasClass("chapter")) == true)
                || tag == "h2"
            {
                // 标题节点
                saveChapter()
                curTitle = (try? el.text()) ?? "Chapter \(idx+1)"
            } else {
                // 段落节点
                let text = (try? el.text()) ?? ""
                curText += text + "\n\n"
            }
        }
        // 收尾最后一章
        saveChapter()
    }

    private func copyToDocuments(_ url: URL) throws -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dst  = docs.appendingPathComponent(url.lastPathComponent)
        if fm.fileExists(atPath: dst.path) {
            try fm.removeItem(at: dst)
        }
        try fm.copyItem(at: url, to: dst)
        return dst
    }

    /// Extract cover image from PDF, EPUB, or DOCX file
    private func extractCoverImage(from url: URL, type: BookFileType) -> Data? {
        switch type {
        case .pdf:
            if let pdfDoc = PDFDocument(url: url),
               let firstPage = pdfDoc.page(at: 0) {
                let pageRect = firstPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(CGRect(origin: .zero, size: pageRect.size))
                    ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    firstPage.draw(with: .mediaBox, to: ctx.cgContext)
                }
                return image.jpegData(compressionQuality: 0.8)
            }
            
        case .epub:
            return extractEPUBCover(from: url)
            
        case .docx:
            return extractDOCXCover(from: url)
            
        default:
            return nil
        }
        return nil
    }
    
    /// Extract cover image from EPUB file
    private func extractEPUBCover(from url: URL) -> Data? {
        // Create a temporary directory to extract EPUB contents
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Extract EPUB (which is a ZIP file) to temp directory
            try FileManager.default.unzipItem(at: url, to: tempDir)
            
            // Read container.xml to find the OPF file
            let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
            guard let containerData = try? Data(contentsOf: containerURL),
                  let containerString = String(data: containerData, encoding: .utf8),
                  let opfPath = containerString.range(of: "full-path=\"([^\"]+)\"", options: .regularExpression)
                    .map({ String(containerString[$0].split(separator: "\"")[1]) }) else {
                return nil
            }
            
            // Read OPF file to find cover image
            let opfURL = tempDir.appendingPathComponent(opfPath)
            guard let opfData = try? Data(contentsOf: opfURL),
                  let opfString = String(data: opfData, encoding: .utf8) else {
                return nil
            }
            
            // Look for cover image in OPF metadata
            if let coverId = opfString.range(of: "id=\"([^\"]+)\"[^>]*properties=\"[^\"]*cover-image[^\"]*\"", options: .regularExpression)
                .map({ String(opfString[$0].split(separator: "\"")[1]) }),
               let href = opfString.range(of: "id=\"\(coverId)\"[^>]*href=\"([^\"]+)\"", options: .regularExpression)
                .map({ String(opfString[$0].split(separator: "\"")[1]) }) {
                
                // Get the cover image path
                let coverPath = (opfPath as NSString).deletingLastPathComponent + "/" + href
                let coverURL = tempDir.appendingPathComponent(coverPath)
                
                // Read and return the cover image data
                return try? Data(contentsOf: coverURL)
            }
            
            // If no cover-image property found, try to find the first image in the book
            if let firstImage = opfString.range(of: "href=\"([^\"]+\\.(jpg|jpeg|png))\"", options: .regularExpression)
                .map({ String(opfString[$0].split(separator: "\"")[1]) }) {
                
                let imagePath = (opfPath as NSString).deletingLastPathComponent + "/" + firstImage
                let imageURL = tempDir.appendingPathComponent(imagePath)
                
                return try? Data(contentsOf: imageURL)
            }
        } catch {
            print("Error extracting EPUB cover: \(error)")
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        return nil
    }
    
    /// Extract cover image from DOCX file
    private func extractDOCXCover(from url: URL) -> Data? {
        // Create a temporary directory to extract DOCX contents
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Extract DOCX (which is a ZIP file) to temp directory
            try FileManager.default.unzipItem(at: url, to: tempDir)
            
            // Look for cover image in media folder
            let mediaDir = tempDir.appendingPathComponent("word/media")
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: mediaDir.path) {
                let mediaFiles = try fileManager.contentsOfDirectory(at: mediaDir, includingPropertiesForKeys: nil)
                
                // Find the first image file
                if let firstImage = mediaFiles.first(where: { url in
                    let ext = url.pathExtension.lowercased()
                    return ["jpg", "jpeg", "png"].contains(ext)
                }) {
                    return try? Data(contentsOf: firstImage)
                }
            }
        } catch {
            print("Error extracting DOCX cover: \(error)")
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        return nil
    }
}

