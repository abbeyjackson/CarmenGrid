//
//  PhotoDetail.swift
//  Carmen's Drawing Frame
//
//  Created by Abbey Jackson on 2019-04-07.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit

class PhotoDetail: Codable {
    let filename: String
    var timestamp: TimeInterval
    var gridType: Int = 0
    var gridColor: Int = 0
    
    init(filename: String, timestamp: TimeInterval, gridType: Int = 0, gridColor: Int = 0) {
        self.filename = filename
        self.timestamp = timestamp
        self.gridType = gridType
        self.gridColor = gridColor
    }
}
