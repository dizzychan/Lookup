//
//  Item.swift
//  Lookup6
//
//  Created by Wangzhen Wu on 23/03/2025.
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
