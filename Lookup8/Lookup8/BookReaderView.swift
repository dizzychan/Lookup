//
//  BookReaderView.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

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

/// 1) 归一化换行：\r\n/\r -> \n，去掉段落间空格
/// 2) 按 “\n\n” 切段落，保留双换行标记
/// 3) 再按空格拆词，得到 tokens
fileprivate func paginate(content: String,
                          fontSize: CGFloat,
                          containerSize: CGSize,
                          padding: CGFloat = 16) -> [String] {
  // —— 一行归一化：把所有换行先改成空格 ——
  let flat = content
    .replacingOccurrences(of: "\r\n", with: " ")
    .replacingOccurrences(of: "\n",   with: " ")
  
  let words = flat.split(whereSeparator: \.isWhitespace).map(String.init)
  let usableW = containerSize.width  - 2 * padding
  let usableH = containerSize.height - 2 * padding
  let font    = UIFont.systemFont(ofSize: fontSize)

  var pages: [String] = []
  var cur = ""
  for w in words {
    let next = cur.isEmpty ? w : cur + " " + w
    if measureHeight(of: next, font: font, width: usableW) > usableH {
      pages.append(cur)
      cur = w
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
  
  // —— 从 SettingView 拿来的用户偏好 ——
  @AppStorage("readerFontSize")   private var fontSize    = 18.0
  @AppStorage("readerFontDesign") private var fontStyleRaw = FontStyle.system.rawValue

  let book: Book
  @Query private var allChapters: [Chapter]

  @State private var chapterList        = [Chapter]()
  @State private var pages              = [String]()
  @State private var currentChapterIndex = 0
  @State private var currentPageIndex    = 0

  /// 只有阅读区域用这个动态字体
  private var readerFont: Font {
    let style = FontStyle(rawValue: fontStyleRaw) ?? .system
    return .system(
      size: CGFloat(fontSize),
      weight: .regular,
      design: style.design
    )
  }

  private var isBookmarkedThisPage: Bool {
    book.lastReadPageByChapter[currentChapterIndex] == currentPageIndex
  }

  var body: some View {
    GeometryReader { geo in
      VStack {
        // — 章标题 —
        if chapterList.indices.contains(currentChapterIndex) {
          Text(chapterList[currentChapterIndex].title)
            .font(.headline)
            .padding(.top, 8)
        }

        // — 分页展示 —
        TabView(selection: $currentPageIndex) {
          ForEach(pages.indices, id: \.self) { idx in
            Text(pages[idx])
              .font(readerFont)                   // ← 用动态字体
              .lineSpacing(6)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)
              .padding(.horizontal, 16)
              .padding(.top, 8)
              .padding(.bottom, 24)
              .textSelection(.enabled)

              .frame(
                width: geo.size.width,
                height: geo.size.height - 44 - 50,
                alignment: .topLeading
              )
              .tag(idx)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .onAppear { setup(geo.size) }
        .onChange(of: fontSize)    { _ in recalcPages(geo.size) }
        .onChange(of: fontStyleRaw){ _ in recalcPages(geo.size) }

        // — Prev/Next —
        HStack {
          Button("Prev") {
            if currentChapterIndex > 0 {
              loadChapter(currentChapterIndex - 1, geometry: geo.size)
            }
          }
          .disabled(currentChapterIndex == 0)

          Spacer()

          Button("Next") {
            if currentChapterIndex < chapterList.count - 1 {
              loadChapter(currentChapterIndex + 1, geometry: geo.size)
            }
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

  // —— 以下逻辑不变 ——
  private func setup(_ size: CGSize) {
    chapterList = allChapters
      .filter { $0.book.id == book.id }
      .sorted { $0.index < $1.index }

    if chapterList.isEmpty {
      pages = paginate(content: book.content,
                       fontSize: CGFloat(fontSize),
                       containerSize: size)
    } else {
      loadChapter(0, geometry: size)
    }

    if let saved = book.lastReadPageByChapter[currentChapterIndex],
       saved < pages.count {
      currentPageIndex = saved
    }
  }

  private func loadChapter(_ idx: Int, geometry: CGSize) {
    currentChapterIndex = idx
    recalcPages(geometry)
  }

  private func recalcPages(_ geometry: CGSize) {
    let text = chapterList.isEmpty
      ? book.content
      : chapterList[currentChapterIndex].content

    pages = paginate(content: text,
                     fontSize: CGFloat(fontSize),
                     containerSize: geometry)

    if let saved = book.lastReadPageByChapter[currentChapterIndex],
       saved < pages.count {
      currentPageIndex = saved
    } else {
      currentPageIndex = 0
    }
  }

  private func toggleChapterBookmark() {
    if isBookmarkedThisPage {
      book.lastReadPageByChapter[currentChapterIndex] = nil
    } else {
      book.lastReadPageByChapter[currentChapterIndex] = currentPageIndex
    }
    try? context.save()
  }
}

