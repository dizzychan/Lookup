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

struct ImportView: View {
    @Environment(\.modelContext) private var context
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let err = errorMessage {
                    Text("Error: \(err)")
                        .foregroundColor(.red)
                }

                Button("Import File") {
                    isImporting = true
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [
                        .plainText,
                        .pdf,
                        .epub,
                        UTType.html,
                        .item
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
            }
            .padding()
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
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Import error:", error)
        }
    }

    /// —— 只保留一个“统一分章”函数 ——
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

        // 3) 找所有可能的“章节标题”节点
        let h3s = (try? doc.select("h3.chapter").array()) ?? []
        let allH2s = (try? doc.select("h2").array()) ?? []
        // 过滤 Gutenberg 那种 “CHAPTER 1.”、“CHAPTER I” 之类
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
}

