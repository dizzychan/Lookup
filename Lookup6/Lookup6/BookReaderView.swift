import SwiftUI
import SwiftData
import UIKit   // UIFont, NSAttributedString

// MARK: — 分页辅助函数 —（请保持和 ReaderView 同步）
fileprivate func measureHeight(of text: String, font: UIFont, width: CGFloat) -> CGFloat {
  let attr = NSAttributedString(string: text, attributes: [.font: font])
  let rect = attr.boundingRect(
    with: CGSize(width: width, height: .greatestFiniteMagnitude),
    options: [.usesLineFragmentOrigin, .usesFontLeading],
    context: nil
  )
  return ceil(rect.height)
}

fileprivate func paginate(content: String,
                          fontSize: CGFloat,
                          containerSize: CGSize,
                          padding: CGFloat = 16) -> [String] {
  let words = content.split(separator: " ")
  let usableW = containerSize.width - 2 * padding
  let usableH = containerSize.height - 2 * padding
  let font = UIFont.systemFont(ofSize: fontSize)

  var pages: [String] = []
  var cur = ""
  for w in words {
    let next = cur.isEmpty ? String(w) : cur + " " + w
    if measureHeight(of: next, font: font, width: usableW) > usableH {
      if !cur.isEmpty { pages.append(cur) }
      cur = String(w)
    } else {
      cur = next
    }
  }
  if !cur.isEmpty { pages.append(cur) }
  return pages
}

// MARK: — 分章 + 分页 + 章内书签 —

struct BookReaderView: View {
  @Environment(\.modelContext) private var context
  @AppStorage("readerFontSize") private var fontSize: Double = 18

  let book: Book
  @Query private var allChapters: [Chapter]   // 只取章节

  // —— 状态 ——
  @State private var chapterList: [Chapter] = []
  @State private var currentChapterIndex: Int = 0
  @State private var pages: [String] = []
  @State private var currentPageIndex: Int = 0

  /// 本章本页是否已标记
  private var isBookmarkedThisPage: Bool {
    book.lastReadPageByChapter[currentChapterIndex] == currentPageIndex
  }

  var body: some View {
    GeometryReader { geo in
      VStack {
        // 章标题
        if currentChapterIndex < chapterList.count {
          Text(chapterList[currentChapterIndex].title)
            .font(.headline)
            .padding(.top, 8)
        }

        // 分页展示
        TabView(selection: $currentPageIndex) {
          ForEach(pages.indices, id: \.self) { idx in
            Text(pages[idx])
              .font(.system(size: fontSize))
              .frame(
                width: geo.size.width,
                height: geo.size.height - 100, // 底部留空
                alignment: .topLeading
              )
              .padding()
              .tag(idx)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .onAppear { setup(geo.size) }
        .onChange(of: fontSize) { _ in recalcPages(geo.size) }

        // 章间切换按钮
        HStack {
          Button("Prev") {
            guard currentChapterIndex > 0 else { return }
            loadChapter(currentChapterIndex - 1, geometry: geo.size)
          }
          .disabled(currentChapterIndex == 0)

          Spacer()

          Button("Next") {
            guard currentChapterIndex < chapterList.count - 1 else { return }
            loadChapter(currentChapterIndex + 1, geometry: geo.size)
          }
          .disabled(currentChapterIndex >= chapterList.count - 1)
        }
        .padding()
      }
      .navigationTitle(book.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            toggleChapterBookmark()
          } label: {
            Image(systemName: isBookmarkedThisPage ? "bookmark.fill" : "bookmark")
              .foregroundColor(isBookmarkedThisPage ? .red : .primary)
          }
        }
      }
    }
  }

  // MARK: — 逻辑拆分 —

  private func setup(_ size: CGSize) {
    // 1) 拿本书所有章节并排序
    chapterList = allChapters
      .filter { $0.book.id == book.id }
      .sorted { $0.index < $1.index }

    // 2) 第1章或全文分页
    if chapterList.isEmpty {
      pages = paginate(
        content: book.content,
        fontSize: CGFloat(fontSize),
        containerSize: size
      )
    } else {
      loadChapter(0, geometry: size)
    }

    // 3) 如果已有记录，就跳到对应章&页
    if let savedPage = book.lastReadPageByChapter[currentChapterIndex],
       savedPage < pages.count
    {
      currentPageIndex = savedPage
    }
  }

  private func loadChapter(_ idx: Int, geometry: CGSize) {
    currentChapterIndex = idx
    recalcPages(geometry)
  }

  private func recalcPages(_ geometry: CGSize) {
    let content = chapterList.isEmpty
      ? book.content
      : chapterList[currentChapterIndex].content

    pages = paginate(
      content: content,
      fontSize: CGFloat(fontSize),
      containerSize: geometry
    )

    // 如果本章已经有记录，则跳转到它，否则回到 0
    if let saved = book.lastReadPageByChapter[currentChapterIndex],
       saved < pages.count
    {
      currentPageIndex = saved
    } else {
      currentPageIndex = 0
    }
  }

  /// 打／取消 本章本页的书签
  private func toggleChapterBookmark() {
    if isBookmarkedThisPage {
      book.lastReadPageByChapter[currentChapterIndex] = nil
    } else {
      book.lastReadPageByChapter[currentChapterIndex] = currentPageIndex
    }
    try? context.save()
  }
}

