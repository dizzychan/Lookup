// ReaderView.swift
import SwiftUI
import SwiftData
import UIKit   // 用于 UIFont、NSAttributedString

// MARK: — 分页辅助函数 —

// 1) 计算一段文字在指定字体、指定宽度下的高度
fileprivate func measureHeight(of text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let attr = NSAttributedString(string: text, attributes: [.font: font])
    let rect = attr.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
    )
    return ceil(rect.height)
}

// 2) 按「一屏一页」把长字符串拆成若干页
fileprivate func paginate(
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
            if !current.isEmpty { pages.append(current) }
            current = String(w)
        } else {
            current = candidate
        }
    }
    if !current.isEmpty { pages.append(current) }
    return pages
}

// MARK: — 阅读器视图 + 单页书签 —

struct ReaderView: View {
    /// 绑定 Book 实例，可以直接改动并自动保存
    @Bindable var book: Book
    @Environment(\.modelContext) private var context

    @AppStorage("readerFontSize") private var fontSize: Double = 18
    @State private var pages: [String] = []
    @State private var currentPage: Int = 0

    /// 本页是否已做书签
    private var isBookmarked: Bool {
        // 在字典里有此 key 即表示这页被标记过
        book.lastReadPageByChapter[currentPage] != nil
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
                // 首次分页
                pages = paginate(
                    content: book.content,
                    fontSize: CGFloat(fontSize),
                    containerSize: geo.size,
                    padding: 16
                )
                // 如果想自动跳到上次阅读页，可以：
                // currentPage = book.lastReadPageByChapter.values.first ?? 0
            }
            .onChange(of: fontSize) { _ in
                // 字体变后重分页，保持或修正当前页
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

    /// 在字典里新增／移除当前页的标记
    private func togglePageBookmark() {
        if isBookmarked {
            // 取消标记
            book.lastReadPageByChapter[currentPage] = nil
        } else {
            // 标记到字典里
            book.lastReadPageByChapter[currentPage] = currentPage
        }
        try? context.save()
    }
}

