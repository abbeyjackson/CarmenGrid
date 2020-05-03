//
//  ViewSetUp.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import UIKit

typealias ViewSetUp = ViewController
extension ViewSetUp {
    func setUpViews() {
        loadPreviousRotationSettings()
        setUpButtons()
        setUpLockLabel()
        setUpImagePicker()
        setUpPhotoViews()
        setInitialVisibleIndex()
    }
    
    private func loadPreviousRotationSettings() {
        guard let previousRotationString = UserDefaults.standard.string(forKey: persistance.displayRotationKey),
            let previousRotation = DisplayRotation(rawValue: previousRotationString)  else {
                Log.logVerbose("SETUP>> Previous rotation settings: none")
                return
        }
        Log.logInfo("SETUP>> Previous rotation settings: \(previousRotationString)")
        rotation = previousRotation
    }
    
    private func setUpButtons() {
        for button in buttons {
            guard let name = button.accessibilityLabel else { return }
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.tintColor = UIColor.gray
            button.imageView?.contentMode = .scaleAspectFit
        }
        
        let addPhotoGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped))
        addPhotoGesture.numberOfTapsRequired = 1
        photoButton.addGestureRecognizer(addPhotoGesture)
        
        let clearGesture = UILongPressGestureRecognizer(target: self, action: #selector(clearPhotos(gesture:)))
        photoButton.addGestureRecognizer(clearGesture)
    }
    
    private func setUpLockLabel() {
        lockedLabel.text = UserMessage.viewLocked.message
        let unlockGesture = UITapGestureRecognizer(target: self, action: #selector(lockTapped(_:)))
        unlockGesture.numberOfTapsRequired = 2
        lockedLabel.addGestureRecognizer(unlockGesture)
        lockedLabel.isHidden = true
        lockedLabel.transform = DisplayRotation.portrait.transform
    }
    
    private func setUpImagePicker() {
        imagePickerController.modalPresentationStyle = .pageSheet
        imagePickerController.delegate = self as UINavigationControllerDelegate & UIImagePickerControllerDelegate
    }
    
    private func setUpPhotoViews() {
        photoScrollView.delegate = self
        photoScrollView.minimumZoomScale = 1
        photoScrollView.maximumZoomScale = 4
        photoView.contentMode = .scaleAspectFit
    }
    
    private func setInitialVisibleIndex() {
        persistance.visibleIndex = UserDefaults.standard.integer(forKey: persistance.visibleIndexKey)
        Log.logVerbose("SETUP>> Number of photos to store: \(persistance.numberOfPhotosToStore)")
        Log.logVerbose("SETUP>> Previously saved visible index: \(persistance.visibleIndex)")
    }
}
