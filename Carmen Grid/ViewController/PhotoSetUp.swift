//
//  PhotoSetUp.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import UIKit
import Photos

typealias PhotoSetUp = ViewController
extension PhotoSetUp : PHPhotoLibraryAvailabilityObserver {
    
    func setUpPhotoLibraryPermissions() {
        let status = PHPhotoLibrary.authorizationStatus()
        Log.logInfo("Photo Permission status: \(status)")
        
        switch status {
        case .notDetermined:
            Log.logVerbose("SETUP>> Showing PHPhotoLibrary authorization request")
            PHPhotoLibrary.requestAuthorization { status in
                if status != .authorized {
                    DispatchQueue.main.async {
                        self.showPermissionError()
                    }
                }
            }
        case .authorized:
            break
        default:
           showPermissionError()
        }
    }
    
    func photoLibraryDidBecomeUnavailable(_ photoLibrary: PHPhotoLibrary) {
        DispatchQueue.main.async {
            self.instructionLabel.text = UserMessage.noPhotos.message
            self.refresh()
        }
    }
    
    private func showPermissionError() {
        Log.logVerbose("SETUP>> Showing permission error on instruction label")
        instructionLabel.isHidden = false
        instructionLabel.text = UserMessage.noPermission.message
    }
    
    func showPermissionAlert() {
        Log.logVerbose("Showing denied permissions alert")
        let alert = UIAlertController(title: "Error", message: UserMessage.noPermission.alertMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.view.isHidden = true
        present(alert, animated: false) {
            alert.view.transform = self.photoButton.transform
            alert.view.isHidden = false
        }
    }
}
