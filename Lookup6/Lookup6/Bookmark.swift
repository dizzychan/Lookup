// Bookmark.swift
import SwiftData
import Foundation

@Model
class Bookmark {
  // SwiftData 要求加一个唯一主键
  @Attribute(.unique) var id: UUID = UUID()
  
  // 对应哪本书（SwiftData 内部的 PersistentIdentifier）
  var bookId: PersistentIdentifier
  
  // 书签记录到哪一章
  var chapterIndex: Int
  
  // 记录到那一页
  var pageIndex: Int

  init(
    bookId: PersistentIdentifier,
    chapterIndex: Int,
    pageIndex: Int
  ) {
    self.bookId       = bookId
    self.chapterIndex = chapterIndex
    self.pageIndex    = pageIndex
  }
}

