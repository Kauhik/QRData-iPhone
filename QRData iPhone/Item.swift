//
//  Item.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
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
