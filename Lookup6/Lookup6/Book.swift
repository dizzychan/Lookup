import SwiftData
import Foundation

/// 用来区分文件类型：txt, pdf, epub, docx, 或者未知
enum BookFileType: String, Codable {
    case txt
    case pdf
    case epub
    case docx
    case unknown
}

@Model
class Book {
    @Attribute(.unique)
    var id: UUID = UUID()
    
    var title: String
    var content: String     // 对于 txt 文件，可以直接存全文
    var isPinned: Bool
    var fileType: BookFileType   // 标记此书的文件类型
    var fileURL: String?         // 如果是pdf/epub/docx等非纯文本文件，就记录文件路径
    //新加的一个
    var chapters: [Chapter] = []

    var bookmarkedPages: [Int] = []

    /// - Parameters:
    ///   - title: 书名
    ///   - content: 书的正文（仅对 txt 文件有效）
    ///   - isPinned: 是否置顶
    ///   - fileType: 文件类型（txt、pdf、epub、docx 等）
    ///   - fileURL: 如果不是 txt，就把本地文件路径存这里
    init(title: String,
         content: String = "",
         isPinned: Bool = false,
         fileType: BookFileType = .txt,
         fileURL: String? = nil) {
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.fileType = fileType
        self.fileURL = fileURL
    }
}

