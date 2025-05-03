//
//  Chapter.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import SwiftData
import Foundation

@Model
class Chapter {
    @Attribute(.unique)
    var id: UUID = UUID()

    var index: Int
    var title: String
    var content: String

    /// 反向指回 Book.chapters
    var book: Book

    init(index: Int, title: String, content: String, book: Book) {
        self.index = index
        self.title = title
        self.content = content
        self.book = book
    }
}

