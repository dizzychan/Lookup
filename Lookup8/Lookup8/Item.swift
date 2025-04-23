//
//  Item.swift
//  Lookup8
//
//  Created by Wangzhen Wu on 22/04/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
