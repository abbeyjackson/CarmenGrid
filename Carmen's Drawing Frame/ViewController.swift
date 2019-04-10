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
    let displayRotationKey = "displayRotation"
    let numberOfPhotosToStore = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpPhotoLibraryPermissions()
        loadPreviousRotationSettings()
        retrieveSavedPhotos()
        setInitialVisiblePhoto()
        
        setUpImagePicker()
        setUpPhotoViews()
        setUpButtons()
        setUpLockLabel()
        
        DispatchQueue.main.async {
            self.refreshVisiblePhoto()
            self.addGridView()
            self.loadInitialGridViewSettings()
            self.setVisibilityForButtons()
        }
        deleteStaleImageFiles()
    }
}

typealias PhotoSetUp = ViewController
extension PhotoSetUp {
    func setUpPhotoLibraryPermissions() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in }
        case .authorized:
            break
        default:
            let alert = UIAlertController(title: "Uh Oh!", message: "You have denied Carmen Grid access to your photos so you won't be able to load any photos into this app. Please visit your device's permission settings to allow access", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
    }
    func loadPreviousRotationSettings() {
        guard let rotationString = UserDefaults.standard.string(forKey: displayRotationKey),
            let rotation = DisplayRotation(rawValue: rotationString)  else {
                photoParentView.transform = DisplayRotation.landscape.transform
                return
        }
        switch rotation {
        case .portrait: setPortraitRotation()
        case .landscape: setLandscapeRotation()
        }
    }
    func retrieveSavedPhotos() {
        let decoder = JSONDecoder()
        guard let detailsData = UserDefaults.standard.array(forKey: loadedPhotosKey) as? [Data] else { return }
        print("Retrieved \(detailsData.count) photo details from UserDefaults.")
        for detailData in detailsData {
            if let detail = try? decoder.decode(PhotoDetail.self, from: detailData) {
                let path = defaultsDirectory.appendingPathComponent(detail.filename)
                if let imageData = try? Data(contentsOf: path), let image = UIImage(data: imageData) {
                    let loadedPhoto = LoadedPhoto(image: image, detail: detail)
                    loadedPhotos.append(loadedPhoto)
                } else {
                    print("Could not load photo with filename: \(path.lastPathComponent)")
                }
            } else {
                print("Could not decode data")
            }
        }
        print("There are \(loadedPhotos.count) photos loaded")
        loadedPhotos.sortByTimestamp()
    }
    
    func setInitialVisiblePhoto() {
        visibleIndex = UserDefaults.standard.integer(forKey: visibleIndexKey)
        if visibleIndex >= numberOfPhotosToStore {
            visibleIndex = 0
            deleteStaleImageFiles()
        }
    }
    
    func loadInitialGridViewSettings() {
        let photo = loadedPhotos[safe: visibleIndex]
        if let gridTypeInt = photo?.detail.gridType, let gridType = PhotoGrid.GridType(rawValue: gridTypeInt), let gridColorInt = photo?.detail.gridColor, let gridColor = PhotoGrid.GridColor(rawValue: gridColorInt) {
            print("initial grid set to saved settings with gridType: \(gridType)")
            self.gridView?.set(type: gridType, color: gridColor)
        } else {
            print("initial grid set to default settings")
            gridView?.set(type: .none, color: .white)
        }
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
        guard let loadedPhoto = loadedPhotos[safe: visibleIndex] else {
            print("No visible photo")
            photoView.image = nil
            return
        }
        photoView.image = loadedPhoto.image
        let isPortrait = photoParentView.transform == DisplayRotation.portrait.transform
        isPortrait ? setPortraitRotation() : setLandscapeRotation()
        setVisibilityForButtons()
        setVisibilityForGrid()
    }
    
    func setVisibilityForGrid() {
        guard let photo = loadedPhotos[safe: visibleIndex], let gridType = PhotoGrid.GridType(rawValue: photo.detail.gridType), let gridColor = PhotoGrid.GridColor(rawValue: photo.detail.gridColor) else { return }
        print("Setting up grid visibility")
        gridView?.set(type: gridType, color: gridColor)
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
        updateDefaults()
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
        gridView?.swapLineColor { newGridColor in
            let photo = loadedPhotos[safe: visibleIndex]
            photo?.detail.gridColor = newGridColor.rawValue
        }
        updateDefaults()
    }
    
    @IBAction func gridTapped(_ sender: UIButton) {
        let photo = loadedPhotos[safe: visibleIndex]
        if let gridView = gridView {
            gridView.swapGrid { newGridType in
                photo?.detail.gridType = newGridType.rawValue
            }
        } else {
            addGridView()
            photo?.detail.gridType = 1
        }
        
        print("Grid type now \(String(describing: photo?.detail.gridType))")
        updateDefaults()
        setVisibilityForPaletteButton()
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        var rotation: DisplayRotation
        if photoParentView.transform == DisplayRotation.landscape.transform {
            setPortraitRotation()
            rotation = DisplayRotation.portrait
        } else {
            setLandscapeRotation()
            rotation = DisplayRotation.landscape
        }
        
        updateDefaults(new: rotation)
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
        picker.dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let path = info[UIImagePickerController.InfoKey.imageURL] as? URL else { return }
            
            var filename = path.lastPathComponent
            if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                print("Asset exists, using unique identifier for filename")
                filename =  asset.localIdentifier.replacingOccurrences(of: "/", with: "-")
            }
            
            var image = originalImage
            if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                print("Edited image exists, loading user edited image")
                image = editedImage
            }

            let loadedPhoto = LoadedPhoto(image: image, detail: PhotoDetail(filename: filename, timestamp: Date().timeIntervalSince1970))
            strongSelf.addNew(loadedPhoto)
            strongSelf.setVisibilityForButtons()
        }
    }
}

typealias Grid = ViewController
extension Grid {
    func addGridView() {
        gridView = PhotoGrid()
        if let gridView = gridView {
            let isPortrait = photoParentView.transform == DisplayRotation.portrait.transform
            gridView.backgroundColor = UIColor.clear
            gridView.alpha = 0.3
            if let size = photoView.image?.size {
                let newSize = isPortrait ? scaleToPortrait(size) : scaleToLandscape(size)
                gridView.frame = newSize
            } else {
                gridView.frame = photoView.frame
            }
            photoView.addSubview(gridView)
        }
    }
}

typealias Rotation = ViewController
extension Rotation {
    func setPortraitRotation() {
        print("setPortraitRotation")
        buttons.forEach { $0.transform = DisplayRotation.portrait.transform }
        photoParentView.transform = DisplayRotation.portrait.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToPortrait(size)
        photoView.bounds = newSize
        gridView?.frame = newSize
    }
    
    func setLandscapeRotation() {
        print("setLandscapeRotation")
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
        print("addNew")
        loadPhoto(photo)
        refreshVisiblePhoto()
        save(photo)
        deleteStaleImageFiles()
        updateDefaults()
    }
    
    func loadPhoto(_ photo: LoadedPhoto) {
        if let matchingIndex = loadedPhotos.firstIndex(where: { $0.detail.filename == photo.detail.filename }) {
            print("timestamp updated on matching index")
            loadedPhotos[matchingIndex].detail.timestamp = photo.detail.timestamp
            loadedPhotos.sortByTimestamp()
            visibleIndex = 0
        } else {
            print("new photo inserted at index 0")
            loadedPhotos.insert(photo, at: 0)
            visibleIndex = 0
        }
        updateDefaults()
    }
    
    func save(_ loadedPhoto: LoadedPhoto) {
        guard let imageData = loadedPhoto.image.pngData() else { return }
        let savePath = defaultsDirectory.appendingPathComponent(loadedPhoto.detail.filename)
        do {
            try imageData.write(to: savePath)
            print("Image written to disk with filename: \(loadedPhoto.detail.filename)")
        } catch {
            print("Couldn't write \(loadedPhoto.detail.filename)")
        }
    }
    
    func deleteStaleImageFiles() {
        if loadedPhotos.count > numberOfPhotosToStore {
            print("There are \(loadedPhotos.count) loaded photos, deleting stale image files.")
            for index in numberOfPhotosToStore..<loadedPhotos.count {
                let photoToDelete = loadedPhotos[index]
                let deletePath = defaultsDirectory.appendingPathComponent(photoToDelete.detail.filename)
                do {
                    try FileManager.default.removeItem(at: deletePath)
                    loadedPhotos.remove(at: index)
                    print("Deleted photo at index \(index)")
                } catch {
                    print("Couldn't delete photo at \(photoToDelete.detail.filename)")
                }
            }
        }
        
        do {
            let existingFilenames = try FileManager.default.contentsOfDirectory(at: defaultsDirectory, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }
            let extraFilenames = Set(existingFilenames).subtracting(Set(loadedPhotos.map { $0.detail.filename }))
            guard extraFilenames.count > 0 else {
                print("No extra files to delete")
                return
            }
            for filename in extraFilenames {
                let path = defaultsDirectory.appendingPathComponent(filename)
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    print("Could not delete \(filename)")
                }
            }
        } catch {
            print("Could not retrieve all filenames")
        }
    }
    
    func updateDefaults(new rotation: DisplayRotation? = nil) {
        let encoder = JSONEncoder()
        let details = loadedPhotos.compactMap { try? encoder.encode($0.detail) }
        UserDefaults.standard.set(details, forKey: loadedPhotosKey)
        print("There are \(loadedPhotos.count) loaded photos")
        print("Updating defaults with \(details.count) details")
        UserDefaults.standard.set(visibleIndex, forKey: visibleIndexKey)
        if let rotation = rotation {
            UserDefaults.standard.set(rotation.rawValue, forKey: displayRotationKey)
        }
    }
}
