//
//  Book.swift
//  Lookup3.0
//
//  Created by Wangzhen Wu on 21/03/2025.
//
import SwiftData
import Foundation

@Model
class Book {
    var title: String
    var author: String
    var progress: Double
    var content: String?
    
    // 其余省略，也可以有 @Attribute(.unique) var id: UUID
    init(title: String, author: String, progress: Double = 0.0, content: String? = nil) {
        self.title = title
        self.author = author
        self.progress = progress
        self.content = content
    }
}


