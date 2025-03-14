//
//  Item.swift
//  Lookup
//
//  Created by Dizzy Chan on 07/03/2025.
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
