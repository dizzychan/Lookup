//
//  Chapter.swift
//  Lookup6
//
//  Created by Wangzhen Wu on 28/03/2025.
//
import SwiftData
import Foundation

@Model
class Chapter {
    @Attribute(.unique)
    var id: UUID = UUID()
    
    /// 章节序号，例如第 1 章、第 2 章
    var index: Int
    
    /// 章节标题，比如 "第一章"、"Chapter 1"
    var title: String
    
    /// 该章节的全文内容
    var content: String
    
    /// 与 Book 模型关联：代表本章节属于哪本书
    var book: Book

    /// - Parameters:
    ///   - index: 本章节的序号（从 1 开始或 0 开始都可以自行决定）
    ///   - title: 章节标题
    ///   - content: 章节文本
    ///   - book: 关联到的图书对象
    init(index: Int, title: String, content: String, book: Book) {
        self.index = index
        self.title = title
        self.content = content
        self.book = book
    }
}

