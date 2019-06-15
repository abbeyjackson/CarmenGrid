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
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var instructionLabel: UILabel!
    
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
    let loadedPhotoPrefix = "loaded-"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showInstructionLabel()
        setUpPhotoLibraryPermissions()
    }
}

typealias PhotoSetUp = ViewController
extension PhotoSetUp {
    func showInstructionLabel() {
        instructionLabel.transform = photoView.transform
        instructionLabel.isHidden = false
        instructionLabel.text = """
        Welcome!
        
        To get started tap the photo icon.
        
        If you need to clear photos to start
        over again long press on the photo icon.
        """
    }
    
    func setUpPhotoLibraryPermissions() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in }
        case .authorized:
            break
        default:
           showPermissionError()
        }
    }
    
    func showPermissionError() {
        instructionLabel.isHidden = false
        instructionLabel.text = """
        Uh Oh!
        
        You have denied Carmen Grid access to your photos
        so you won't be able to load any photos into this app.
        
        Please visit your device's permission settings to allow access
        """
    }
    
    func showPermissionAlert() {
        let alert = UIAlertController(title: "Error", message: "You have denied access to your Photo Library. Please open your device Settings, tap on \"Privacy\" and allow Photos access for Carmen Grid.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.view.isHidden = true
        self.present(alert, animated: false) {
            alert.view.transform = self.photoView.transform
            alert.view.isHidden = false
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
        for detailData in detailsData {
            if let detail = try? decoder.decode(PhotoDetail.self, from: detailData) {
                let path = defaultsDirectory.appendingPathComponent(detail.filename)
                if let imageData = try? Data(contentsOf: path), let image = UIImage(data: imageData) {
                    let loadedPhoto = LoadedPhoto(image: image, detail: detail)
                    loadedPhotos.append(loadedPhoto)
                } else {
                }
            } else {
            }
        }
        loadedPhotos.sortByTimestamp()
    }
    
    func setInitialVisiblePhoto() {
        visibleIndex = UserDefaults.standard.integer(forKey: visibleIndexKey)
        if visibleIndex >= numberOfPhotosToStore {
            visibleIndex = 0
            deleteStaleImageFiles()
        }
        instructionLabel.isHidden = true
    }
    
    func loadInitialGridViewSettings() {
        let photo = loadedPhotos[safe: visibleIndex]
        if let gridTypeInt = photo?.detail.gridType, let gridType = PhotoGrid.GridType(rawValue: gridTypeInt), let gridColorInt = photo?.detail.gridColor, let gridColor = PhotoGrid.GridColor(rawValue: gridColorInt) {
            self.gridView?.set(type: gridType, color: gridColor)
        } else {
            gridView?.set(type: .none, color: .white)
        }
    }
}

typealias ViewSetUp = ViewController
extension ViewSetUp {
    func setUpImagePicker() {
        imagePickerController.modalPresentationStyle = .pageSheet
        imagePickerController.delegate = self as UINavigationControllerDelegate & UIImagePickerControllerDelegate
    }
    
    func setUpPhotoViews() {
        photoScrollView.delegate = self
        photoScrollView.minimumZoomScale = 1
        photoScrollView.maximumZoomScale = 4
    }
    
    func setUpButtons() {
        for button in buttons {
            guard let name = button.accessibilityLabel else { return }
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: .normal)
            button.tintColor = UIColor.gray
            button.imageView?.contentMode = .scaleAspectFit
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
            photoView.image = nil
            return
        }
        photoView.image = loadedPhoto.image
        let isPortrait = photoParentView.transform == DisplayRotation.portrait.transform
        isPortrait ? setPortraitRotation() : setLandscapeRotation()
        setVisibilityForButtons()
        setVisibilityForGrid()
        instructionLabel.isHidden = true
    }
    
    func setVisibilityForGrid() {
        guard let photo = loadedPhotos[safe: visibleIndex], let gridType = PhotoGrid.GridType(rawValue: photo.detail.gridType), let gridColor = PhotoGrid.GridColor(rawValue: photo.detail.gridColor) else { return }
        gridView?.set(type: gridType, color: gridColor)
    }
}

typealias ButtonActions = ViewController
extension ButtonActions {
    @IBAction func photoTapped(_ sender: UIButton) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            let alert = UIAlertController(title: "Error", message: "You have denied access to your Photo Library. Please open your device Settings, tap on \"Privacy\" and allow Photos access for Carmen Grid.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            let alert = UIAlertController(title: "Error", message: "Your device can not display the photo library", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(okAction)
            alert.view.isHidden = true
            self.present(alert, animated: false) {
                alert.view.transform = self.photoView.transform
                alert.view.isHidden = false
            }
            return
        }
        
        self.present(imagePickerController, animated: true, completion: nil)
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
    
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        print("content inset changed")
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        print("Did zoom:")
        print(photoView.frame)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        print("Will zoom:")
        print(photoView.frame)
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
            
            var image = originalImage
            if let editedImage = info[.editedImage] as? UIImage {
                image = editedImage
            }

            let photoDetail = PhotoDetail(filename: strongSelf.loadedPhotoPrefix + filename, timestamp: Date().timeIntervalSince1970)
            let loadedPhoto = LoadedPhoto(image: image, detail: photoDetail)
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
        buttons.forEach { $0.transform = DisplayRotation.portrait.transform }
        photoParentView.transform = DisplayRotation.portrait.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToPortrait(size)
        photoView.bounds = newSize
        gridView?.frame = newSize
        imagePickerController.view.transform = DisplayRotation.portrait.transform
    }
    
    func setLandscapeRotation() {
        buttons.forEach { $0.transform = DisplayRotation.landscape.transform }
        photoParentView.transform = DisplayRotation.landscape.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToLandscape(size)
        photoView.bounds = photoParentView.bounds
        gridView?.frame = newSize
        imagePickerController.view.transform = DisplayRotation.landscape.transform
    }
}

typealias Persistance = ViewController
extension Persistance {
    func addNew(_ photo: LoadedPhoto) {
        loadPhoto(photo) { success in
            guard success else { return }
            self.refreshVisiblePhoto()
            self.save(photo)
            self.deleteStaleImageFiles()
            self.updateDefaults()
        }
    }
    
    func loadPhoto(_ photo: LoadedPhoto, success: @escaping (Bool) -> ()) {
        if let matchingIndex = loadedPhotos.firstIndex(where: { $0.detail.filename == photo.detail.filename }), matchingIndex < numberOfPhotosToStore {
            loadedPhotos[matchingIndex].detail.timestamp = photo.detail.timestamp
            loadedPhotos.sortByTimestamp()
            visibleIndex = 0
            success(true)
        } else if loadedPhotos.count == numberOfPhotosToStore {
            let alert = UIAlertController(title: "Warning", message: "You have 3 photos loaded already. Replace current photo?", preferredStyle: .alert)
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
            self.present(alert, animated: false) {
                alert.view.transform = self.photoView.transform
                alert.view.isHidden = false
            }
        } else {
            self.loadedPhotos.insert(photo, at: self.visibleIndex)
            success(true)
        }
    }
    
    func save(_ loadedPhoto: LoadedPhoto) {
        guard let imageData = loadedPhoto.image.pngData() else { return }
        
        let savePath = defaultsDirectory.appendingPathComponent(loadedPhoto.detail.filename)
        do {
            try imageData.write(to: savePath)
        } catch {
        }
    }
    
    func deleteExtraLoadedPhotos() {
        if loadedPhotos.count > numberOfPhotosToStore {
            for index in numberOfPhotosToStore..<loadedPhotos.count {
                let photoToDelete = loadedPhotos[index]
                let deletePath = defaultsDirectory.appendingPathComponent(photoToDelete.detail.filename)
                do {
                    try FileManager.default.removeItem(at: deletePath)
                    loadedPhotos.remove(at: index)
                } catch {
                }
            }
        }
    }
    
    func deleteStaleImageFiles() {
        deleteExtraLoadedPhotos()
        deleteExtraSavedPhotos()
    }
    
    func deleteExtraSavedPhotos() {
        do {
            let existingFilenames = try FileManager.default.contentsOfDirectory(at: defaultsDirectory, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }.filter { $0.contains(loadedPhotoPrefix)}
            let extraFilenames = Set(existingFilenames).subtracting(Set(loadedPhotos.map { $0.detail.filename }))
            guard extraFilenames.count > 0 else { return }
            for filename in extraFilenames {
                let path = defaultsDirectory.appendingPathComponent(filename)
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                }
            }
        } catch {
        }
    }
    
    func updateDefaults(new rotation: DisplayRotation? = nil) {
        let encoder = JSONEncoder()
        let details = loadedPhotos.compactMap { try? encoder.encode($0.detail) }
        UserDefaults.standard.set(details, forKey: loadedPhotosKey)
        UserDefaults.standard.set(visibleIndex, forKey: visibleIndexKey)
        if let rotation = rotation {
            UserDefaults.standard.set(rotation.rawValue, forKey: displayRotationKey)
        }
    }
}
