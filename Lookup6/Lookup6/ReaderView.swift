import SwiftUI
import SwiftData
import UIKit  // 用于 measureHeight 中的 UIFont、NSAttributedString

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

/// 将全文拆分成多个“屏幕页”，每页在给定宽度、高度和字体大小下恰好容纳
fileprivate func paginate(content: String,
                          fontSize: CGFloat,
                          containerSize: CGSize,
                          padding: CGFloat = 16) -> [String] {
    // 简单地按空格拆分文本
    let words = content.split(separator: " ")
    
    // 给文本留出上下左右 padding，避免贴边
    let usableWidth = containerSize.width - 2 * padding
    let usableHeight = containerSize.height - 2 * padding
    
    let font = UIFont.systemFont(ofSize: fontSize)
    
    var pages: [String] = []
    var currentText = ""
    
    for word in words {
        // 拼接下一个单词
        let newText = currentText.isEmpty
            ? String(word)
            : currentText + " " + word
        
        // 测量拼接后的文本高度
        let height = measureHeight(of: newText, font: font, width: usableWidth)
        
        // 如果超过一页高度，则把之前的 currentText 存为一页，并重新开始
        if height > usableHeight {
            if !currentText.isEmpty {
                pages.append(currentText)
            }
            currentText = String(word)
        } else {
            // 还在当前页累加
            currentText = newText
        }
    }
    
    // 最后剩余的 currentText 也要加入
    if !currentText.isEmpty {
        pages.append(currentText)
    }
    
    return pages
}

// 用于把长文本简单按固定字符数拆分成多个“页面” (可选，如果你还想保留 chunked 功能)
extension String {
    func chunked(by size: Int) -> [String] {
        var result = [String]()
        let length = self.count
        var startIndex = self.startIndex
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            let substring = self[startIndex..<endIndex]
            result.append(String(substring))
            startIndex = endIndex
        }
        
        return result
    }
}

struct ReaderView: View {
    let book: Book
    
    @AppStorage("readerFontSize") private var fontSize: Double = 18
    @State private var pages: [String] = []
    @State private var currentPage: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    Text(pages[index])
                        .font(.system(size: fontSize))
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                        .padding()
                }
            }
            .tabViewStyle(.page)
            .onAppear {
                // 首次出现时进行分页
                pages = paginate(
                    content: book.content,
                    fontSize: CGFloat(fontSize),
                    containerSize: geometry.size,
                    padding: 16
                )
                print("ReaderView appear: book.content length=\(book.content.count)")
            }
            
            .onChange(of: fontSize) { newValue in
                // 如果字体大小变化，重新分页，并回到第 0 页
                pages = paginate(
                    content: book.content,
                    fontSize: CGFloat(newValue),
                    containerSize: geometry.size,
                    padding: 16
                )
                currentPage = 0
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

