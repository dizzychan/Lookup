// BookReaderView.swift
import SwiftUI
import SwiftData
import UIKit // measureHeight + UIFont

// ——— 分页辅助，请务必和下面的 ReaderView 保持一致 ———
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

// ——— BookReaderView with Bookmark ———
struct BookReaderView: View {
  let book: Book

  // 拿所有章节
  @Query private var allChapters: [Chapter]
  // 拿所有书签
  @Query private var allBookmarks: [Bookmark]

  @Environment(\.modelContext) private var context
  @AppStorage("readerFontSize") private var fontSize: Double = 18

  @State private var chapterList: [Chapter] = []
  @State private var currentChapterIndex = 0

  // 将当前章内容再分页
  @State private var pages: [String] = []
  @State private var currentPageIndex = 0

  // 看看本书有没有书签
  private var bookmark: Bookmark? {
    allBookmarks.first { $0.bookId == book.id }
  }

  var body: some View {
    GeometryReader { geo in
      VStack {
        // 章节标题
        if currentChapterIndex < chapterList.count {
          Text(chapterList[currentChapterIndex].title)
            .font(.headline)
            .padding(.top, 8)
        }

        // 分页翻页
        TabView(selection: $currentPageIndex) {
          ForEach(pages.indices, id: \.self) { idx in
            Text(pages[idx])
              .font(.system(size: fontSize))
              .frame(
                width: geo.size.width,
                height: geo.size.height - 100,
                alignment: .topLeading
              )
              .padding()
              .tag(idx)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .onAppear {
          setupChapters(geometry: geo.size)
        }
        .onChange(of: fontSize) { _ in
          recalcPages(geometry: geo.size)
        }

        // 上下章按钮
        HStack {
          Button("Prev") {
            guard currentChapterIndex > 0 else { return }
            loadChapter(currentChapterIndex - 1, geometry: geo.size)
          }.disabled(currentChapterIndex == 0)

          Spacer()

          Button("Next") {
            guard currentChapterIndex < chapterList.count - 1 else { return }
            loadChapter(currentChapterIndex + 1, geometry: geo.size)
          }.disabled(currentChapterIndex >= chapterList.count - 1)
        }
        .padding()
      }
      .navigationTitle(book.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            toggleBookmark()
          } label: {
            Image(systemName: bookmark == nil ? "bookmark" : "bookmark.fill")
              .foregroundColor(bookmark == nil ? .primary : .red)
          }
        }
      }
    }
  }

  // MARK: — 逻辑拆分 —

  private func setupChapters(geometry: CGSize) {
    let cs = allChapters
      .filter { $0.book.id == book.id }
      .sorted { $0.index < $1.index }
    chapterList = cs

    if cs.isEmpty {
      // 纯文本没章节
      pages = paginate(
        content: book.content,
        fontSize: CGFloat(fontSize),
        containerSize: geometry
      )
    } else {
      loadChapter(0, geometry: geometry)
    }

    // 如果有书签就跳到那页
    if let bm = bookmark,
       bm.chapterIndex < chapterList.count,
       bm.pageIndex < pages.count
    {
      currentChapterIndex = bm.chapterIndex
      currentPageIndex = bm.pageIndex
    }
  }

  private func loadChapter(_ idx: Int, geometry: CGSize) {
    currentChapterIndex = idx
    recalcPages(geometry: geometry)
  }

  private func recalcPages(geometry: CGSize) {
    let content = chapterList.isEmpty
      ? book.content
      : chapterList[currentChapterIndex].content

    pages = paginate(
      content: content,
      fontSize: CGFloat(fontSize),
      containerSize: geometry
    )
    // 如果书签在本章，保持它，否则跳到 0
    if let bm = bookmark, bm.chapterIndex == currentChapterIndex {
      currentPageIndex = min(bm.pageIndex, pages.count - 1)
    } else {
      currentPageIndex = 0
    }
  }

  private func toggleBookmark() {
    if let bm = bookmark {
      bm.chapterIndex = currentChapterIndex
      bm.pageIndex    = currentPageIndex
    } else {
      let bm = Bookmark(
        bookId:        book.id,
        chapterIndex:  currentChapterIndex,
        pageIndex:     currentPageIndex
      )
      context.insert(bm)
    }
    try? context.save()
  }
}

