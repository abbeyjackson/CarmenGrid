//
//  ArrayExtensions.swift
//  Carmen's Drawing Frame
//
//  Created by Abbey Jackson on 2019-04-07.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

extension Array {
    subscript (safe index: Int) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
    
}

extension Array where Element == LoadedPhoto {
    mutating func sortByTimestamp() {
        self.sort { $0.detail.timestamp > $1.detail.timestamp }
    }
}
