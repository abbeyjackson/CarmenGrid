//
//  PhotoGridEnums.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-04-08.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit

extension PhotoGrid {
    enum GridColor: Int {
        case white, black, red, blue
        
        var color: CGColor {
            switch self {
            case .white: return UIColor.white.cgColor
            case .black: return UIColor.black.cgColor
            case .red: return UIColor.red.cgColor
            case .blue: return UIColor.blue.cgColor
            }
        }
    }
    
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
}
