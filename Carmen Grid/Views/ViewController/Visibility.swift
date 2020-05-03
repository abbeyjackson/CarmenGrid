//
//  Visibility.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2020-05-02.
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
    
    func clearPhotoView() {
        self.photoView.image = nil
        self.photoView.set(type: .none)
    }
    
    func reloadVisiblePhoto() {
        guard let loadedPhoto = loadedPhotos[safe: visibleIndex] else {
            Log.logVerbose("No photo at visible index: \(visibleIndex), loadPhotos count: \(loadedPhotos.count)")
            photoView.image = nil
            instructionLabel.isHidden = false
            return
        }
        Log.logVerbose("Visible index: \(visibleIndex), loadPhotos count: \(loadedPhotos.count)")
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
        
        swapButton.isEnabled = isPhotoLoaded && loadedPhotos.count > 1
    }
    
    private func setVisibilityForPaletteButton() {
        let photo = loadedPhotos[safe: visibleIndex]
        let gridVisible = photo != nil && photo?.detail.gridType != GridType.none.rawValue
        let paletteAlpha = gridVisible ? 1.0 : 0.0
        paletteButton.alpha = CGFloat(paletteAlpha)
        paletteButton.isUserInteractionEnabled = gridVisible
    }
    
    private func setVisibilityForGrid() {
        guard let photo = loadedPhotos[safe: visibleIndex],
            let gridType = GridType(rawValue: photo.detail.gridType),
            let gridColor = GridColor(rawValue: photo.detail.gridColor) else {
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
