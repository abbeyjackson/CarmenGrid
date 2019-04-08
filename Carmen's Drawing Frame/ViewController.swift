//
//  ViewController.swift
//  Carmen's Drawing Frame
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
    @IBOutlet weak var photoView: UIImageView!
    
    @IBOutlet weak var lockedLabel: UILabel!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var swapButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var paletteButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet var buttons: [UIButton]!
    
    var gridView: PhotoGrid?
    var imagePickerController = UIImagePickerController()
    
    var loadedPhotos: [LoadedPhoto] = []
    var visibleIndex: Int = 0
    
    let defaultsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let loadedPhotosKey = "loadedPhotos"
    let visibleIndexKey = "visibleIndex"
    let numberOfPhotosToStore = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        
        retrieveSavedPhotos()
        loadInitialVisiblePhoto()
        setUpImagePicker()
        setUpPhotoViews()
        setUpButtons()
        setUpLockLabel()
        deleteStaleImageFiles()
    }
}

typealias PhotoSetUp = ViewController
extension PhotoSetUp {
    func retrieveSavedPhotos() {
        let decoder = JSONDecoder()
        guard let detailsData = UserDefaults.standard.array(forKey: loadedPhotosKey) as? [Data] else { return }
        for detailData in detailsData {
            if let detail = try? decoder.decode(PhotoDetail.self, from: detailData) {
                let path = defaultsDirectory.appendingPathComponent(detail.filename)
                if let imageData = try? Data(contentsOf: path), let image = UIImage(data: imageData) {
                    let loadedPhoto = LoadedPhoto(image: image, detail: detail)
                    loadedPhotos.append(loadedPhoto)
                }
            }
        }
        loadedPhotos.sortByTimestamp()
    }
    
    func loadInitialVisiblePhoto() {
        visibleIndex = UserDefaults.standard.integer(forKey: visibleIndexKey)
        if visibleIndex >= numberOfPhotosToStore {
            visibleIndex = 0
        }
        refreshVisiblePhoto()
    }
}

typealias ViewSetUp = ViewController
extension ViewSetUp {
    func setUpImagePicker() {
        imagePickerController.modalPresentationStyle = UIModalPresentationStyle.currentContext
        imagePickerController.delegate = self as UINavigationControllerDelegate & UIImagePickerControllerDelegate
    }
    
    func setUpPhotoViews() {
        photoScrollView.delegate = self
        photoScrollView.minimumZoomScale = 1
        photoScrollView.maximumZoomScale = 4
        photoParentView.transform = DisplayRotation.landscape.transform
    }
    
    func setUpButtons() {
        let imageInset = CGFloat(2)
        let hotizontalInsets = CGFloat(0)
        
        for button in buttons {
            guard let name = button.accessibilityLabel else { return }
            let verticalInsets = CGFloat(button.bounds.height/4)
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.tintColor = UIColor.gray
            button.imageEdgeInsets = UIEdgeInsets(top: imageInset,
                                                  left: imageInset,
                                                  bottom: imageInset,
                                                  right: imageInset)
            button.contentEdgeInsets = UIEdgeInsets(top: verticalInsets, left: hotizontalInsets, bottom: verticalInsets, right: hotizontalInsets)
        }
        
        setVisibilityForButtons()
    }
    
    func setUpLockLabel() {
        lockedLabel.text = "View is Locked\nDouble tap to unlock"
        let unlockGesture = UITapGestureRecognizer(target: self, action: #selector(lockTapped(_:)))
        unlockGesture.numberOfTapsRequired = 2
        lockedLabel.addGestureRecognizer(unlockGesture)
        lockedLabel.isHidden = true
        lockedLabel.transform = DisplayRotation.portrait.transform
    }
}

typealias Visibility = ViewController
extension Visibility {
    func setVisibilityForButtons() {
        swapButton.isEnabled = loadedPhotos.count > 1
        
        let isPhotoLoaded = (photoView.image != nil)
        let mainAlpha = isPhotoLoaded ? 1.0 : 0.0
        
        lockButton.alpha = CGFloat(mainAlpha)
        lockButton.isUserInteractionEnabled = isPhotoLoaded
        
        gridButton.alpha = CGFloat(mainAlpha)
        gridButton.isUserInteractionEnabled = isPhotoLoaded
        
        setVisibilityForPaletteButton()
    }
    
    func setVisibilityForPaletteButton() {
        let gridVisible = (gridView != nil) && gridView?.gridType != PhotoGrid.GridType.none
        let paletteAlpha = gridVisible ? 1.0 : 0.0
        paletteButton.alpha = CGFloat(paletteAlpha)
        paletteButton.isUserInteractionEnabled = gridVisible
    }
    
    func refreshVisiblePhoto() {
        DispatchQueue.main.async {
            self.clearGrid()
            guard let loadedPhoto = self.loadedPhotos[safe: self.visibleIndex] else {
                self.photoView.image = nil
                return
            }
            let isPortrait = self.photoParentView.transform == DisplayRotation.portrait.transform
            let newSize = isPortrait ? self.scaleToPortrait(loadedPhoto.image.size) : self.photoParentView.bounds
            self.photoView.image = loadedPhoto.image
            self.photoView.bounds = newSize
            self.setVisibilityForButtons()
        }
    }
}

typealias ButtonActions = ViewController
extension ButtonActions {
    @IBAction func photoTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "Your device can not display the photo library", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func swapTapped(_ sender: UIButton) {
        visibleIndex = (visibleIndex + 1) == loadedPhotos.count ? 0 : (visibleIndex + 1)
        refreshVisiblePhoto()
        UserDefaults.standard.set(visibleIndex, forKey: visibleIndexKey)
    }
    
    @IBAction func lockTapped(_ sender: UIButton) {
       let showButtons = buttonsView.isHidden
        lockedLabel.isHidden = showButtons
        buttonsView.isUserInteractionEnabled = showButtons
        buttonsView.isHidden = !showButtons
        lockedLabel.isUserInteractionEnabled = !showButtons
        photoScrollView.isUserInteractionEnabled = showButtons
    }
    
    @IBAction func paletteTapped(_ sender: UIButton) {
        gridView?.swapLineColour()
    }
    
    @IBAction func gridTapped(_ sender: UIButton) {
        if let gridView = gridView {
            gridView.swapGrid()
        } else {
            addGridView()
        }
        
        setVisibilityForPaletteButton()
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        if photoParentView.transform == DisplayRotation.landscape.transform {
            setPortraitRotation()
        } else {
            setLandscapeRotation()
        }
    }
}

typealias Scaling = ViewController
extension Scaling {
    func contentScaleOfPhoto(size: CGSize) -> CGFloat {
        let width = size.width
        let height = size.height
        let widthScale = photoParentView.bounds.size.width / width
        let heightScale = photoParentView.bounds.size.height / height
        return min(widthScale, heightScale)
    }
    
    func scaledWidthOfPhoto(size: CGSize) -> CGFloat {
        let contentScale = contentScaleOfPhoto(size: size)
        return size.width * contentScale
    }
    
    func scaledHeightOfPhoto(size: CGSize) -> CGFloat {
        let contentScale = contentScaleOfPhoto(size: size)
        return size.height * contentScale
    }
    
    func scaleToLandscape(_ size: CGSize) -> CGRect {
        let scaledWidth = scaledWidthOfPhoto(size: size)
        let scaledHeight = scaledHeightOfPhoto(size: size)
        let xValue = (photoParentView.frame.width - scaledWidth) / 2
        let yValue = (photoParentView.frame.height - scaledHeight) / 2
        
        let scaledSize = CGRect(x: xValue, y: yValue, width: scaledWidth, height: scaledHeight)
        return scaledSize
    }
    
    func scaleToPortrait(_ size: CGSize) -> CGRect {
        let scale = size.height / size.width
        var newWidth = photoParentView.bounds.height
        var newHeight = newWidth * scale
        if scale >= 1.0 { // Portrait oriented photo
            newHeight = photoParentView.bounds.width
            newWidth = newHeight / scale
        }
        
        let xValue = (photoParentView.bounds.width - newWidth) / 2
        let yValue = (photoParentView.bounds.height - newHeight) / 2
        
        let scaledSize = CGRect(x: xValue, y: yValue, width: newWidth, height: newHeight)
        return scaledSize
    }
}

typealias Delegates = ViewController
extension Delegates: UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoView
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:  [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let path = info[UIImagePickerController.InfoKey.imageURL] as? URL else { return }
            let filename = path.lastPathComponent
            let loadedPhoto = LoadedPhoto(image: image, detail: PhotoDetail(filename: filename, timestamp: Date().timeIntervalSince1970))
            strongSelf.addNew(loadedPhoto)
            strongSelf.setVisibilityForButtons()
        }
    }
}

typealias Grid = ViewController
extension Grid {
    func addGridView() {
        guard let size = photoView.image?.size else { return }
        gridView = PhotoGrid()
        if let gridView = gridView {
            let isPortrait = photoParentView.transform == DisplayRotation.portrait.transform
            let newSize = isPortrait ? scaleToPortrait(size) : scaleToLandscape(size)
            gridView.backgroundColor = UIColor.clear
            gridView.alpha = 0.3
            gridView.frame = newSize
            photoView.addSubview(gridView)
        }
    }
    
    func clearGrid() {
        gridView?.removeFromSuperview()
        gridView = nil
    }
}

typealias Rotation = ViewController
extension Rotation {
    func setPortraitRotation() {
        buttons.forEach { $0.transform = DisplayRotation.portrait.transform }
        photoParentView.transform = DisplayRotation.portrait.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToPortrait(size)
        photoView.bounds = newSize
        gridView?.frame = newSize
    }
    
    func setLandscapeRotation() {
        buttons.forEach { $0.transform = DisplayRotation.landscape.transform }
        photoParentView.transform = DisplayRotation.landscape.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToLandscape(size)
        photoView.bounds = photoParentView.bounds
        gridView?.frame = newSize
    }
}

typealias Persistance = ViewController
extension Persistance {
    func addNew(_ photo: LoadedPhoto) {
        loadPhoto(photo)
        refreshVisiblePhoto()
        save(photo)
        deleteStaleImageFiles()
        updateDefaults()
    }
    
    func loadPhoto(_ photo: LoadedPhoto) {
        if let matchingIndex = loadedPhotos.firstIndex(where: { $0.detail.filename == photo.detail.filename }) {
            loadedPhotos[matchingIndex].detail.timestamp = photo.detail.timestamp
            loadedPhotos.sortByTimestamp()
            visibleIndex = matchingIndex
        } else {
            loadedPhotos.insert(photo, at: 0)
            visibleIndex = 0
        }
        UserDefaults.standard.set(visibleIndex, forKey: visibleIndexKey)
    }
    
    func save(_ loadedPhoto: LoadedPhoto) {
        guard let imageData = loadedPhoto.image.pngData() else { return }
        let savePath = defaultsDirectory.appendingPathComponent(loadedPhoto.detail.filename)
        do {
            try imageData.write(to: savePath)
        } catch {
            print("Couldn't write \(loadedPhoto.detail.filename)")
        }
    }
    
    func deleteStaleImageFiles() {
        if loadedPhotos.count > numberOfPhotosToStore {
            for index in numberOfPhotosToStore..<loadedPhotos.count {
                let photoToDelete = loadedPhotos[index - 1]
                let deletePath = defaultsDirectory.appendingPathComponent(photoToDelete.detail.filename)
                do {
                    try FileManager.default.removeItem(at: deletePath)
                    loadedPhotos.remove(at: index)
                } catch {
                    print("Couldn't delete photo at \(photoToDelete.detail.filename)")
                }
            }
        }
    }
    
    func updateDefaults() {
        let encoder = JSONEncoder()
        let details = loadedPhotos.compactMap { try? encoder.encode($0.detail)
        }
        UserDefaults.standard.set(details, forKey: loadedPhotosKey)
    }
}
