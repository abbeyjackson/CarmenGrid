//
//  Alerts.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import UIKit

typealias Alerts = ViewController
extension Alerts {
    func showNoPhotoLibraryAlert() {
        Log.logError("Device can not display photo library")
        let alert = UIAlertController(title: "Error", message: "Your device can not display the photo library", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.view.isHidden = true
        present(alert, animated: false) {
            alert.view.transform = self.photoButton.transform
            alert.view.isHidden = false
        }
    }
    
    func showMaxPhotoAlert(_ photo: LoadedPhoto, success: @escaping (Bool) -> ()) {
        Log.logInfo("Showing user max number of photos alert")
        let alert = UIAlertController(title: "Warning", message: "You have \(numberOfPhotosToStore) photos loaded already. Replace current photo?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Replace Current", style: .destructive) { _ in
            self.loadedPhotos[self.visibleIndex] = photo
            success(true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            success(false)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        alert.view.isHidden = true
        present(alert, animated: false) {
            alert.view.transform = self.photoButton.transform
            alert.view.isHidden = false
        }
    }
    
    func showRotateToShareAlert() {
        let alert = UIAlertController(title: "Share Photo", message: "To share the photo the screen must rotate to landscape.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Rotate", style: .destructive) { _ in
            self.rotation = self.rotation.rotate
            self.setRotation {
                self.showShareSheet()
            }
            Log.logVerbose("User sharing image")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            Log.logVerbose("User cancelled sharing photo")
        }
        alert.addAction(yesAction)
        alert.addAction(cancelAction)
        alert.view.isHidden = true
        alert.view.transform = self.photoParentView.transform
        present(alert, animated: false) {
            alert.view.transform = self.photoButton.transform
            alert.view.isHidden = false
        }
    }
    
    func showShareSheet() {
        guard let image = photoView.image else { return }
        
        let shareSheet = UIActivityViewController(activityItems: [image], applicationActivities: [])
        shareSheet.popoverPresentationController?.sourceView = self.shareButton.imageView
        shareSheet.view.isHidden = true
        self.present(shareSheet, animated: true) {
            shareSheet.view.transform = self.photoButton.transform
            shareSheet.view.isHidden = false
        }
    }
    
    func showClearPhotosAlert() {
         Log.logUserEvent("User clearing photos")
         let alert = UIAlertController(title: "Clear All Photos", message: "Are you sure you want to clear all photos?", preferredStyle: .alert)
         let yesAction = UIAlertAction(title: "Clear All Photos", style: .destructive) { _ in
             alert.view.isHidden = true
             self.clearPhotoView()
             self.deleteAllPhotos()
             self.setVisibleViews()
         }
         let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
             alert.view.isHidden = true
             Log.logVerbose("User cancelled clearing photos")
         }
         alert.addAction(yesAction)
         alert.addAction(cancelAction)
         alert.view.isHidden = true
         alert.view.transform = self.photoParentView.transform
         present(alert, animated: false) {
             alert.view.transform = self.photoButton.transform
             alert.view.isHidden = false
         }
    }
}
