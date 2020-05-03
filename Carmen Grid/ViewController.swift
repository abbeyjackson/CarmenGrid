//
//  ViewController.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-03-26.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var scrollParentView: TransparentView!
    @IBOutlet weak var photoScrollView: UIScrollView!
    @IBOutlet weak var photoParentView: UIView!
    @IBOutlet weak var photoView: PhotoGrid!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var lockedLabel: UILabel!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var swapButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var paletteButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet var buttons: [UIButton]!
    
    @IBOutlet weak var photoViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoViewWidthConstraint: NSLayoutConstraint!

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var imagePickerController = UIImagePickerController()

    var rotation: DisplayRotation = .landscape
    
    let persistance = Persistance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        persistance.retrieveSavedPhotos()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        refresh()
        postPhotoLoadSetUp()
        setUpPhotoLibraryPermissions()
        super.viewDidAppear(animated)
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.reloadVisiblePhoto()
            self.setRotation()
            self.setVisibleViews()
        }
    }
}

typealias ButtonActions = ViewController
extension ButtonActions {
    @IBAction func shareTapped(_ sender: UIButton) {
        guard photoView.image != nil else { return }
        
        if rotation == .portrait {
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
        } else {
            showShareSheet()
        }
    }
    
    private func showShareSheet() {
        guard let image = photoView.image else { return }
        
        let shareSheet = UIActivityViewController(activityItems: [image], applicationActivities: [])
        shareSheet.popoverPresentationController?.sourceView = self.shareButton.imageView
        shareSheet.view.isHidden = true
        self.present(shareSheet, animated: true) {
            shareSheet.view.transform = self.photoButton.transform
            shareSheet.view.isHidden = false
        }
    }
    
    @objc func photoTapped() {
        Log.logUserEvent("User adding photo")
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            showPermissionAlert()
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            Log.logError("Device can not display photo library")
            let alert = UIAlertController(title: "Error", message: "Your device can not display the photo library", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(okAction)
            alert.view.isHidden = true
            present(alert, animated: false) {
                alert.view.transform = self.photoButton.transform
                alert.view.isHidden = false
            }
            return
        }
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func clearPhotos(gesture: UIGestureRecognizer) {
        guard gesture.state == .began else { return }
        Log.logUserEvent("User clearing photos")
        let alert = UIAlertController(title: "Clear All Photos", message: "Are you sure you want to clear all photos?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Clear All Photos", style: .destructive) { _ in
            alert.view.isHidden = true
            self.photoView.image = nil
            self.photoView.set(type: .none)
            self.persistance.deleteAllPhotos()
            self.persistance.loadedPhotos.removeAll()
            self.setVisibleViews()
            self.persistance.visibleIndex = 0
            self.persistance.updateDefaults()
            self.instructionLabel.transform = self.rotation.transform
            self.instructionLabel.isHidden = false
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
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
    
    @IBAction func swapTapped(_ sender: UIButton) {
        Log.logUserEvent("User swapping photos")
        persistance.visibleIndex = (persistance.visibleIndex + 1) == persistance.loadedPhotos.count ? 0 : (persistance.visibleIndex + 1)
        DispatchQueue.main.async {
            self.photoView.image = nil
            self.refresh()
        }
        persistance.updateDefaults()
    }
    
    @IBAction func lockTapped(_ sender: UIButton) {
        let showButtons = buttonsView.isHidden
        Log.logUserEvent((showButtons ? "User unlocking screen" : "User locking screen"))
        lockedLabel.isHidden = showButtons
        buttonsView.isUserInteractionEnabled = showButtons
        buttonsView.isHidden = !showButtons
        lockedLabel.isUserInteractionEnabled = !showButtons
        photoScrollView.isUserInteractionEnabled = showButtons
    }
    
    @IBAction func paletteTapped(_ sender: UIButton) {
        Log.logUserEvent("User swapping line color")
        guard let photo = persistance.loadedPhotos[safe: persistance.visibleIndex],
            photo.detail.gridType != 0 else { return }
        photoView.swapLineColor { newGridColor in
            Log.logVerbose("Setting color: \(newGridColor), on photo: \(photo.detail.filename)")
            photo.detail.gridColor = newGridColor.rawValue
        }
        persistance.updateDefaults()
    }
    
    @IBAction func gridTapped(_ sender: UIButton) {
        Log.logUserEvent("User swapping grid type")
        guard let photo = persistance.loadedPhotos[safe: persistance.visibleIndex] else { return }
        
        photoView.swapGrid { newGridType in
            Log.logVerbose("Setting type: \(newGridType), on photo: \(photo.detail.filename)")
            photo.detail.gridType = newGridType.rawValue
        }
        
        persistance.updateDefaults()
        setVisibleViews()
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        Log.logUserEvent("User rotating photo")
        
        rotation = rotation.rotate
        persistance.updateDefaults(new: rotation)
        DispatchQueue.main.async {
            self.setRotation()
        }
    }
}

typealias Delegates = ViewController
extension Delegates: UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoParentView
    }
     
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:  [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            guard let originalImage = info[.originalImage] as? UIImage,
                let path = info[.imageURL] as? URL else { return }
            
            var filename = path.lastPathComponent
            if let asset = info[.phAsset] as? PHAsset {
                filename =  asset.localIdentifier.replacingOccurrences(of: "/", with: "-")
            }
            let formattedFilename = strongSelf.persistance.loadedPhotoPrefix + filename
            
            var image = originalImage
            if let editedImage = info[.editedImage] as? UIImage {
                image = editedImage
            }
            
            Log.logInfo("User selected photo: \(formattedFilename)")
            let photoDetail = PhotoDetail(filename: formattedFilename, timestamp: Date().timeIntervalSince1970)
            let loadedPhoto = LoadedPhoto(image: image, detail: photoDetail)
            strongSelf.addNew(loadedPhoto)
            
            strongSelf.setVisibleViews()
        }
    }
    
    func addNew(_ photo: LoadedPhoto) {
        persistance.addNew(photo, photoLimitAction: { () -> Bool in
            
            var replacePhoto = false
            
            showAlert { result in
                replacePhoto = result
            }
            
            return replacePhoto
        })
        self.refresh()
    }
    
    func showAlert(completion: @escaping (Bool) -> ()) {
        let alert = UIAlertController(title: "Warning", message: "You have \(persistance.numberOfPhotosToStore) photos loaded already. Replace current photo?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Replace Current", style: .destructive) { _ in
            completion(true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        alert.view.isHidden = true
        present(alert, animated: false) {
            alert.view.transform = self.photoButton.transform
            alert.view.isHidden = false
        }
    }
}
