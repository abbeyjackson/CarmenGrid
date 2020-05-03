//
//  PostPhotoViewSetUp.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import Foundation

typealias PostPhotoLoadSetUp = ViewController
extension PostPhotoLoadSetUp {
    func postPhotoLoadSetUp() {
        loadInitialGridViewSettings()
//        setVisibilityForButtons()
        setUpInstructionLabel()
    }
    
    private func setUpInstructionLabel() {
        instructionLabel.transform = rotation.transform
        instructionLabel.isHidden = false
        if instructionLabel.text == nil || instructionLabel.text == "" {
            instructionLabel.text = UserMessage.noPhotos.message
        }
    }
    
    private func loadInitialGridViewSettings() {
        let photo = persistance.loadedPhotos[safe: persistance.visibleIndex]
        if let gridTypeInt = photo?.detail.gridType,
            let gridType = PhotoGrid.GridType(rawValue: gridTypeInt),
            let gridColorInt = photo?.detail.gridColor,
            let gridColor = PhotoGrid.GridColor(rawValue: gridColorInt) {
            photoView.set(type: gridType, color: gridColor)
        } else {
            photoView.set(type: .none)
        }
        Log.logInfo("SETUP>> Initial grid: \(photoView.gridType), and color: \(photoView.lineColor)")
    }
}
