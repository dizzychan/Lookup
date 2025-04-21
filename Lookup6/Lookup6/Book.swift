import SwiftData
import Foundation

/// 用来区分文件类型：txt, pdf, epub, docx, 或者未知
enum BookFileType: String, Codable {
    case txt, pdf, epub, docx, unknown
}

@Model
class Book {
    // 唯一主键
    @Attribute(.unique) var id: UUID = UUID()

    // 书名
    var title: String
    // 纯文本文件的全文；非 txt 类型时可留空
    var content: String
    // 是否置顶
    var isPinned: Bool
    // 文件类型
    var fileType: BookFileType
    // 如果是 pdf/epub/docx，就存本地路径
    var fileURL: String?

    // 章节关系：一对多
    @Relationship(deleteRule: .cascade)
    var chapters: [Chapter] = []

    /// 记录每章最后一次打书签的页码：键 = chapterIndex，值 = pageIndex
    @Attribute
    var lastReadPageByChapter: [Int: Int] = [:]

    init(
        title: String,
        content: String = "",
        isPinned: Bool = false,
        fileType: BookFileType = .txt,
        fileURL: String? = nil
    ) {
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.fileType = fileType
        self.fileURL = fileURL
    }
}

