//
//  Rotation.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import Foundation

typealias Rotation = ViewController
extension Rotation {
    func setRotation(completion: () -> () = {}){
        Log.logInfo("Set Rotation: \(rotation)")
        photoScrollView.zoomScale = 1.0
        imagePickerController.view.transform = rotation.transform
        buttons.forEach { $0.transform = rotation.transform }
        if rotation == .portrait {
            setPortraitRotation(completion)
        } else {
            setLandscapeRotation(completion)
        }
        Log.logInfo("New rotation: \(rotation.rawValue)")
    }
    
    private func setPortraitRotation(_ completion: () -> () = {}) {
        let size = photoView.image?.size ?? view.bounds.size
        let scale = size.height / size.width

        if scale > 1.0 { // Portrait oriented photo
            photoViewHeightConstraint.constant = photoParentView.frame.size.width
            photoViewWidthConstraint.constant = photoParentView.frame.size.width / scale
        } else if scale < 1.0 { // Landscape oriented photo
            photoViewWidthConstraint.constant = photoParentView.frame.size.height
            photoViewHeightConstraint.constant = photoParentView.frame.size.height * scale
        } else {
            photoViewWidthConstraint.constant = photoParentView.frame.size.height
            photoViewHeightConstraint.constant = photoParentView.frame.size.height
        }
        
        photoView.transform = rotation.transform
        photoView.layoutIfNeeded()
        completion()
    }
    
    private func setLandscapeRotation(_ completion: () -> () = {}) {
        let size = photoView.image?.size ?? view.bounds.size
        let scale = size.height / size.width

        if scale > 1.0 { // Portrait oriented photo
            photoViewHeightConstraint.constant = photoParentView.frame.size.height
            photoViewWidthConstraint.constant = photoParentView.frame.size.height / scale
        } else if scale < 1.0 { // Landscape oriented photo
            photoViewWidthConstraint.constant = photoParentView.frame.size.width
            photoViewHeightConstraint.constant = photoParentView.frame.size.width * scale
        } else {
            photoViewWidthConstraint.constant = photoParentView.frame.size.height
            photoViewHeightConstraint.constant = photoParentView.frame.size.height
        }
        
        photoView.transform = rotation.transform
        photoView.layoutIfNeeded()
        completion()
    }
}
