//  ReaderView.swift
import SwiftUI
import SwiftData
import UIKit   // UIFont, NSAttributedString

// MARK: — 分页辅助函数 —

// 1) 计算一段文字在指定字体、指定宽度下的高度
private func measureHeight(of text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let attr = NSAttributedString(string: text, attributes: [.font: font])
    let rect = attr.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
    )
    return ceil(rect.height)
}

// 2) 按「一屏一页」把长字符串拆成若干页
private func paginate(
    content: String,
    fontSize: CGFloat,
    containerSize: CGSize,
    padding: CGFloat = 16
) -> [String] {
    let words = content.split(separator: " ")
    let usableWidth = containerSize.width - 2 * padding
    let usableHeight = containerSize.height - 2 * padding
    let font = UIFont.systemFont(ofSize: fontSize)

    var pages: [String] = []
    var current = ""

    for w in words {
        let candidate = current.isEmpty ? String(w) : current + " " + w
        if measureHeight(of: candidate, font: font, width: usableWidth) > usableHeight {
            // 装不下了 —— 先把 current 当一页 push
            if !current.isEmpty { pages.append(current) }
            current = String(w)
        } else {
            current = candidate
        }
    }
    // 最后一页别忘了
    if !current.isEmpty { pages.append(current) }
    return pages
}


// MARK: — 阅读器视图 + 每页书签 —

struct ReaderView: View {
    @Bindable var book: Book                    // 绑定模型，支持自动保存
    @Environment(\.modelContext) private var context

    @AppStorage("readerFontSize") private var fontSize: Double = 18
    @State private var pages: [String] = []
    @State private var currentPage: Int = 0

    // 本页是否已书签
    private var isBookmarked: Bool {
        book.bookmarkedPages.contains(currentPage)
    }

    var body: some View {
        GeometryReader { geo in
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { idx in
                    Text(pages[idx])
                        .font(.system(size: fontSize))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding()
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onAppear {
                // 分页
                pages = paginate(
                    content: book.content,
                    fontSize: CGFloat(fontSize),
                    containerSize: geo.size,
                    padding: 16
                )
                // 如果想自动跳到某个页，可以在这里设置：
                // currentPage = book.bookmarkedPages.first ?? 0
            }
            .onChange(of: fontSize) { _ in
                // 字体变动后重新分页，保留当前页（或修正到最大页）
                pages = paginate(
                    content: book.content,
                    fontSize: CGFloat(fontSize),
                    containerSize: geo.size,
                    padding: 16
                )
                currentPage = min(currentPage, pages.count - 1)
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        togglePageBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .red : .primary)
                    }
                }
            }
        }
    }

    /// 给当前页打／取消书签
    private func togglePageBookmark() {
        if let idx = book.bookmarkedPages.firstIndex(of: currentPage) {
            // 已有：移除
            book.bookmarkedPages.remove(at: idx)
        } else {
            // 没有：添加
            book.bookmarkedPages.append(currentPage)
        }
        try? context.save()
    }
}

