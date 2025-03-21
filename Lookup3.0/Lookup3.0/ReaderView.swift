//
//  ReaderView.swift
//  Lookup3.0
//
//  Created by Wangzhen Wu on 21/03/2025.
//
import SwiftUI
import SwiftData

struct ReaderView: View {
    @Environment(\.modelContext) private var context
    
    // 直接拿到 Book 对象
    @Bindable var book: Book
    
    // 从设置界面读取字体大小（可选）
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    
    // 每页多少行（简化：按行固定分割）
    private let linesPerPage = 30
    
    // 拆分为“页”
    private var pages: [String] = []
    
    // 当前页索引（0-based）
    @State private var currentPageIndex: Int = 0
    
    // MARK: - 构造 init，或在 onAppear 里做拆分
    init(book: Book) {
        self._book = Bindable(book) // or @Bindable
        self.pages = ReaderView.splitIntoPages(content: book.content ?? "", linesPerPage: 30)
    }
    
    var body: some View {
        TabView(selection: $currentPageIndex) {
            // ForEach每页显示
            ForEach(pages.indices, id: \.self) { index in
                // 一页内容
                VStack(alignment: .leading, spacing: 8) {
                    // 示例：显示标题 + 当前页 / 总页数
                    Text(book.title)
                        .font(.system(size: fontSize + 2))
                        .bold()
                    
                    Text(pages[index])
                        .font(.system(size: fontSize))
                }
                .padding()
                .tag(index) // 用于 TabView 的 selection 匹配
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic)) // 左右翻页
        // 当 currentPageIndex 改变时，更新进度并保存
        .onChange(of: currentPageIndex) { newValue in
            updateReadingProgress(pageIndex: newValue)
        }
        // 在出现时，根据 book.progress 跳转到上次阅读页
        .onAppear {
            let pageCount = max(pages.count, 1)
            // 假设 book.progress = 0.5，则大概在半数页
            let pageFromProgress = Int(Double(pageCount) * book.progress)
            let clampedPage = max(0, min(pageCount - 1, pageFromProgress))
            currentPageIndex = clampedPage
        }
        .navigationTitle("Reading \(book.title)")
    }
    
    // MARK: - 更新进度
    private func updateReadingProgress(pageIndex: Int) {
        let pageCount = max(pages.count, 1)
        // 例如：当前页2，总页数5 => 2 / 5 = 0.4
        let newProgress = Double(pageIndex) / Double(pageCount - 1)
        
        // 如果变化大于一定阈值，就保存
        if abs(book.progress - newProgress) > 0.001 {
            book.progress = newProgress
            do {
                try context.save()
            } catch {
                print("Failed to save page progress: \(error)")
            }
        }
    }
    
    // MARK: - Helper: 按“行数”拆分页
    static func splitIntoPages(content: String, linesPerPage: Int) -> [String] {
        // 先把全文拆成行
        let allLines = content.components(separatedBy: .newlines)
        
        var pages: [String] = []
        var buffer: [String] = []
        
        for line in allLines {
            buffer.append(line)
            if buffer.count >= linesPerPage {
                // 已达一页的行数
                pages.append(buffer.joined(separator: "\n"))
                buffer.removeAll()
            }
        }
        // 处理最后不足一页的部分
        if !buffer.isEmpty {
            pages.append(buffer.joined(separator: "\n"))
        }
        
        // 如果全文非常短，至少要有一页
        if pages.isEmpty {
            pages = ["No content available."]
        }
        
        return pages
    }
}


