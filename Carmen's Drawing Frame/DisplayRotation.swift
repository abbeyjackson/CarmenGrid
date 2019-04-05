//
//  DisplayRotation.swift
//  Carmen's Drawing Frame
//
//  Created by Abbey Jackson on 2019-04-04.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import CoreImage

enum DisplayRotation: String {
    case portrait
    case landscape
    
    var transform: CGAffineTransform {
        switch self {
        case .portrait:
            return CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .landscape:
            return CGAffineTransform(rotationAngle: 0)
        }
    }
}
