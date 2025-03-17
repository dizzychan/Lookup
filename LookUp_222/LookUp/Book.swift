import SwiftData
import Foundation

@Model
class Book {
    var title: String
    var author: String
    var progress: Double
    var pinned: Bool = false
    var content: String?
    
    // 其余省略，也可以有 @Attribute(.unique) var id: UUID
    init(title: String, author: String, progress: Double = 0.0, content: String? = nil) {
        self.title = title
        self.author = author
        self.progress = progress
        self.content = content
        self.pinned = pinned
    }
}

