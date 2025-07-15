//
//  Item.swift
//  EnvVarTool
//
//  Created by Samuel on 2025/7/15.
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
