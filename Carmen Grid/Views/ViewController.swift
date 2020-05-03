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
    
    let defaultsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var loadedPhotos: [LoadedPhoto] = []
    var visibleIndex: Int = 0
    
    let loadedPhotosKey = "loadedPhotos"
    let visibleIndexKey = "visibleIndex"
    let displayRotationKey = "displayRotation"
    let numberOfPhotosToStore = 3
    let loadedPhotoPrefix = "loaded-"
    
    var rotation: DisplayRotation = .landscape
    var imagePickerController = UIImagePickerController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        retrieveSavedPhotos()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.refresh()
            self.postPhotoLoadSetUp()
            self.setUpPhotoLibraryPermissions()
        }
        super.viewDidAppear(animated)
    }
    
    func refresh() {
            self.reloadVisiblePhoto()
            self.setRotation()
            self.setVisibleViews()
    }
}

typealias ButtonActions = ViewController
extension ButtonActions {
    @IBAction func shareTapped(_ sender: UIButton) {
        guard photoView.image != nil else { return }
        
        if rotation == .portrait {
            showRotateToShareAlert()
        } else {
            showShareSheet()
        }
    }
    
    @objc func photoTapped() {
        Log.logUserEvent("User adding photo")
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            showPermissionAlert()
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showNoPhotoLibraryAlert()
            return
        }
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func clearPhotos(gesture: UIGestureRecognizer) {
        guard gesture.state == .began else { return }
        showClearPhotosAlert()
    }
    
    @IBAction func swapTapped(_ sender: UIButton) {
        Log.logUserEvent("User swapping photos")
        visibleIndex = (visibleIndex + 1) == loadedPhotos.count ? 0 : (visibleIndex + 1)
        DispatchQueue.main.async {
            self.photoView.image = nil
            self.refresh()
        }
        updateDefaults()
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
        guard let photo = loadedPhotos[safe: visibleIndex],
            photo.detail.gridType != 0 else { return }
        photoView.swapLineColor { newGridColor in
            Log.logVerbose("Setting color: \(newGridColor), on photo: \(photo.detail.filename)")
            photo.detail.gridColor = newGridColor.rawValue
        }
        updateDefaults()
    }
    
    @IBAction func gridTapped(_ sender: UIButton) {
        Log.logUserEvent("User swapping grid type")
        guard let photo = loadedPhotos[safe: visibleIndex] else { return }
        
        photoView.swapGrid { newGridType in
            Log.logVerbose("Setting type: \(newGridType), on photo: \(photo.detail.filename)")
            photo.detail.gridType = newGridType.rawValue
        }
        
        updateDefaults()
        setVisibleViews()
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        Log.logUserEvent("User rotating photo")
        
        rotation = rotation.rotate
        updateDefaults(new: rotation)
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
            let formattedFilename = strongSelf.loadedPhotoPrefix + filename
            
            var image = originalImage
            if let editedImage = info[.editedImage] as? UIImage {
                image = editedImage
            }
            
            Log.logInfo("User selected photo: \(formattedFilename)")
            let photoDetail = PhotoDetail(filename: formattedFilename, timestamp: Date().timeIntervalSince1970)
            let loadedPhoto = LoadedPhoto(image: image, detail: photoDetail)
            strongSelf.addNew(loadedPhoto)
        }
    }
}
