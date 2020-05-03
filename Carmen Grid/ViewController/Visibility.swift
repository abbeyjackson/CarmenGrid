//
//  Visibility.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import UIKit

typealias Visibility = ViewController
extension Visibility {
    func setVisibleViews() {
        setVisibilityForButtons()
        setVisibilityForGrid()
        setVisibilityForInstructionLabel()
    }
    
    func reloadVisiblePhoto() {
        guard let loadedPhoto = persistance.loadedPhotos[safe: persistance.visibleIndex] else {
            Log.logVerbose("No photo at visible index: \(persistance.visibleIndex), loadPhotos count: \(persistance.loadedPhotos.count)")
            photoView.image = nil
            instructionLabel.isHidden = false
            return
        }
        Log.logVerbose("Visible index: \(persistance.visibleIndex), loadPhotos count: \(persistance.loadedPhotos.count)")
        photoView.image = loadedPhoto.image
    }
    
    private func setVisibilityForButtons() {
        setVisibilityForPhotoActionButtons()
        setVisibilityForPaletteButton()
    }
    
    private func setVisibilityForPhotoActionButtons() {
        let isPhotoLoaded = (photoView.image != nil)
        let mainAlpha = isPhotoLoaded ? 1.0 : 0.0
        
        for button in [lockButton, gridButton, shareButton] {
            button?.alpha = CGFloat(mainAlpha)
            button?.isUserInteractionEnabled = isPhotoLoaded
        }
        
        swapButton.isEnabled = isPhotoLoaded && persistance.loadedPhotos.count > 1
    }
    
    private func setVisibilityForPaletteButton() {
        let photo = persistance.loadedPhotos[safe: persistance.visibleIndex]
        let gridVisible = photo != nil && photo?.detail.gridType != PhotoGrid.GridType.none.rawValue
        let paletteAlpha = gridVisible ? 1.0 : 0.0
        paletteButton.alpha = CGFloat(paletteAlpha)
        paletteButton.isUserInteractionEnabled = gridVisible
    }
    
    private func setVisibilityForGrid() {
        guard let photo = persistance.loadedPhotos[safe: persistance.visibleIndex],
            let gridType = PhotoGrid.GridType(rawValue: photo.detail.gridType),
            let gridColor = PhotoGrid.GridColor(rawValue: photo.detail.gridColor) else {
                Log.logInfo("No photo loaded")
                return
        }
        Log.logInfo("Grid: \(gridType), and color: \(gridColor)")
        photoView.set(type: gridType, color: gridColor)
    }
    
    private func setVisibilityForInstructionLabel() {
        let noPhotos = (photoView.image == nil)
        instructionLabel.isHidden = noPhotos
    }
}
