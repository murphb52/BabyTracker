//
//  Item.swift
//  Baby Tracker
//
//  Created by Brian Murphy on 19/03/2026.
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
