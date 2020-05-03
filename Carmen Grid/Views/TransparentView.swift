//
//  TransparentView.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-03-29.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit

class TransparentView: UIView {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
