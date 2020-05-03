//
//  GridType.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

enum GridType: Int {
    case none, squares, triangles, smallTriangles
    
    var numberOfColumns: Int {
        switch self {
        case .triangles, .squares: return 4
        case .smallTriangles: return GridType.triangles.numberOfColumns * 2
        default: return 0
        }
    }
}
