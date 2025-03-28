//
//  BookReaderView.swift
//  Lookup6
//
//  Created by Wangzhen Wu on 28/03/2025.
//
import SwiftUI
import SwiftData
import UIKit // 用于 measureHeight 和 UIFont

// MARK: - 1. 辅助函数

/// 计算给定文本的高度
fileprivate func measureHeight(of text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let attributedString = NSAttributedString(
        string: text,
        attributes: [.font: font]
    )
    let boundingRect = attributedString.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
    )
    return ceil(boundingRect.height)
}

/// 将一段文本拆分成多个“屏幕页”
fileprivate func paginate(content: String,
                          fontSize: CGFloat,
                          containerSize: CGSize,
                          padding: CGFloat = 16) -> [String] {
    let words = content.split(separator: " ")
    let usableWidth = containerSize.width - 2 * padding
    let usableHeight = containerSize.height - 2 * padding
    let font = UIFont.systemFont(ofSize: fontSize)
    
    var pages: [String] = []
    var currentText = ""
    
    for word in words {
        let newText = currentText.isEmpty ? String(word) : currentText + " " + word
        let height = measureHeight(of: newText, font: font, width: usableWidth)
        
        if height > usableHeight {
            if !currentText.isEmpty {
                pages.append(currentText)
            }
            currentText = String(word)
        } else {
            currentText = newText
        }
    }
    
    if !currentText.isEmpty {
        pages.append(currentText)
    }
    
    return pages
}

// MARK: - 2. BookReaderView

/// 演示「分章节 + 每章节分页」的阅读器
struct BookReaderView: View {
    let book: Book
    
    // 如果你用 iOS 17 的 SwiftData，就可以这样用 @Query 来获取所有 Chapter
    @Query var allChapters: [Chapter]

    @AppStorage("readerFontSize") private var fontSize: Double = 18
    
    // 存储当前书的章节列表（已经排序）
    @State private var chapterList: [Chapter] = []
    // 当前读到第几章 (在 chapterList 的索引)
    @State private var currentChapterIndex: Int = 0
    
    // 当前章节经过分页后的文本页
    @State private var currentChapterPages: [String] = []
    // 当前在章节的第几页
    @State private var currentPageIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // 显示章节标题（可选）
                if currentChapterIndex < chapterList.count {
                    Text(chapterList[currentChapterIndex].title)
                        .font(.headline)
                        .padding(.top, 8)
                }
                
                // 分页展示
                TabView(selection: $currentPageIndex) {
                    ForEach(currentChapterPages.indices, id: \.self) { idx in
                        Text(currentChapterPages[idx])
                            .font(.system(size: fontSize))
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height - 100, // 给底部按钮留空间
                                alignment: .topLeading
                            )
                            .padding()
                    }
                }
                .tabViewStyle(.page)
                .onAppear {
                    // 首次出现时，加载本书的所有章节 -> 显示第 0 章
                    loadChapterListAndShowFirst(geometry: geometry.size)
                }
                .onChange(of: fontSize) { _ in
                    // 字体大小变化 -> 重新分页
                    recalcPages(geometry: geometry.size)
                }
                
                // 按钮：上一章 / 下一章
                HStack {
                    Button("Prev Chapter") {
                        guard currentChapterIndex > 0 else { return }
                        loadChapter(at: currentChapterIndex - 1, geometry: geometry.size)
                    }
                    .disabled(currentChapterIndex <= 0)
                    
                    Spacer()
                    
                    Button("Next Chapter") {
                        guard currentChapterIndex < chapterList.count - 1 else { return }
                        loadChapter(at: currentChapterIndex + 1, geometry: geometry.size)
                    }
                    .disabled(currentChapterIndex >= chapterList.count - 1)
                }
                .padding()
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 第一次进来时，先获取本书所有章节 -> 显示第 0 章
    private func loadChapterListAndShowFirst(geometry: CGSize) {
        // 筛选出与本书相关的章节
        let chaptersForBook = allChapters
            .filter { $0.book.id == book.id }
            .sorted { $0.index < $1.index }
        
        self.chapterList = chaptersForBook
        
        if !chapterList.isEmpty {
            loadChapter(at: 0, geometry: geometry)
        } else {
            // 如果本书没任何章节，可选：要么加载 book.content, 要么提示
            self.currentChapterPages = paginate(
                content: book.content,
                fontSize: CGFloat(fontSize),
                containerSize: geometry
            )
            currentChapterIndex = 0
            currentPageIndex = 0
        }
    }
    
    /// 切换到指定章节
    private func loadChapter(at newIndex: Int, geometry: CGSize) {
        guard newIndex >= 0 && newIndex < chapterList.count else { return }
        currentChapterIndex = newIndex
        recalcPages(geometry: geometry)
    }
    
    /// 根据当前章节 content 进行分页
    private func recalcPages(geometry: CGSize) {
        // 如果 chapterList 为空，就用 book.content
        if chapterList.isEmpty {
            currentChapterPages = paginate(
                content: book.content,
                fontSize: CGFloat(fontSize),
                containerSize: geometry
            )
        } else {
            let chapter = chapterList[currentChapterIndex]
            currentChapterPages = paginate(
                content: chapter.content,
                fontSize: CGFloat(fontSize),
                containerSize: geometry
            )
        }
        currentPageIndex = 0
    }
}

