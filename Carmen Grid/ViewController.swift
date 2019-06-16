//
//  ViewController.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-03-26.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit
import Photos
import Instabug

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
        Instabug.logInfo("Photo Permission status: \(status)")
        
        switch status {
        case .notDetermined:
            Instabug.logVerbose("SETUP>> Showing PHPhotoLibrary authorization request")
            PHPhotoLibrary.requestAuthorization { _ in }
        case .authorized:
            break
        default:
           showPermissionError()
        }
    }
    
    func showPermissionError() {
        Instabug.logVerbose("SETUP>> Showing permission error on instruction label")
        instructionLabel.isHidden = false
        instructionLabel.text = """
        Uh Oh!
        
        You have denied Carmen Grid access to your photos
        so you won't be able to load any photos into this app.
        
        Please visit your device's permission settings to allow access
        """
    }
    
    func showPermissionAlert() {
        Instabug.logVerbose("Showing denied permissions alert")
        let alert = UIAlertController(title: "Error", message: "You have denied access to your Photo Library. Please open your device Settings, tap on \"Privacy\" and allow Photos access for Carmen Grid.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.view.isHidden = true
        present(alert, animated: false) {
            alert.view.transform = self.photoButton.transform
            alert.view.isHidden = false
        }
    }
    
    func loadPreviousRotationSettings() {
        guard let rotationString = UserDefaults.standard.string(forKey: displayRotationKey),
            let rotation = DisplayRotation(rawValue: rotationString)  else {
                Instabug.logVerbose("SETUP>> Previous rotation settings: none")
                photoParentView.transform = DisplayRotation.landscape.transform
                return
        }
        Instabug.logInfo("SETUP>> Previous rotation settings: \(rotationString)")
        switch rotation {
        case .portrait: setPortraitRotation()
        case .landscape: setLandscapeRotation()
        }
    }
    
    func retrieveSavedPhotos() {
        let decoder = JSONDecoder()
        guard let detailsData = UserDefaults.standard.array(forKey: loadedPhotosKey) as? [Data], !detailsData.isEmpty else {
            Instabug.logInfo("SETUP>> Number of previously saved photos: none")
            setLandscapeRotation()
            return
        }
        Instabug.logInfo("SETUP>> Number of previously saved photos: \(detailsData.count)")
        for detailData in detailsData {
            if let detail = try? decoder.decode(PhotoDetail.self, from: detailData) {
                let path = defaultsDirectory.appendingPathComponent(detail.filename)
                if let imageData = try? Data(contentsOf: path), let image = UIImage(data: imageData) {
                    let loadedPhoto = LoadedPhoto(image: image, detail: detail)
                    loadedPhotos.append(loadedPhoto)
                } else {
                    Instabug.logError("SETUP>> Failed retrieving previously saved photo at: \(path)")
                }
            } else {
                Instabug.logError("SETUP>> Failed decoding of previously saved photo details data")
            }
        }
        loadedPhotos.sortByTimestamp()
    }
    
    func setInitialVisiblePhoto() {
        visibleIndex = UserDefaults.standard.integer(forKey: visibleIndexKey)
        Instabug.logVerbose("SETUP>> Number of photos to store: \(numberOfPhotosToStore)")
        Instabug.logVerbose("SETUP>> Previously saved visible index: \(visibleIndex)")
        if visibleIndex >= numberOfPhotosToStore {
            visibleIndex = 0
            deleteStaleImageFiles()
        }
        instructionLabel.isHidden = true
    }
    
    func loadInitialGridViewSettings() {
        guard let gridView = gridView else {
            Instabug.logInfo("SETUP>> Initial grid: none")
            return
        }
        let photo = loadedPhotos[safe: visibleIndex]
        if let gridTypeInt = photo?.detail.gridType,
            let gridType = PhotoGrid.GridType(rawValue: gridTypeInt),
            let gridColorInt = photo?.detail.gridColor,
            let gridColor = PhotoGrid.GridColor(rawValue: gridColorInt) {
            gridView.set(type: gridType, color: gridColor)
        } else {
            gridView.set(type: .none)
        }
        Instabug.logInfo("SETUP>> Initial grid: \(gridView.gridType), and color: \(gridView.lineColor)")
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
        
        let addPhotoGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped))
        addPhotoGesture.numberOfTapsRequired = 1
        photoButton.addGestureRecognizer(addPhotoGesture)
        
        let clearGesture = UILongPressGestureRecognizer(target: self, action: #selector(clearPhotos(gesture:)))
        photoButton.addGestureRecognizer(clearGesture)
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
        photoScrollView.zoomScale = 1.0
        guard let loadedPhoto = loadedPhotos[safe: visibleIndex] else {
            Instabug.logVerbose("No photo at visible index: \(visibleIndex), loadPhotos count: \(loadedPhotos.count)")
            photoView.image = nil
            instructionLabel.isHidden = false
            return
        }
        Instabug.logVerbose("Visible index: \(visibleIndex), loadPhotos count: \(loadedPhotos.count)")
        photoView.image = loadedPhoto.image
        let isPortrait = photoView.transform == DisplayRotation.portrait.transform
        isPortrait ? setPortraitRotation() : setLandscapeRotation()
        setVisibilityForButtons()
        setVisibilityForGrid()
        instructionLabel.isHidden = true
    }
    
    func setVisibilityForGrid() {
        guard let photo = loadedPhotos[safe: visibleIndex],
            let gridView = gridView,
            let gridType = PhotoGrid.GridType(rawValue: photo.detail.gridType),
            let gridColor = PhotoGrid.GridColor(rawValue: photo.detail.gridColor) else {
                Instabug.logInfo("Grid: No grid present")
                return
        }
        Instabug.logInfo("Grid: \(gridView.gridType), and color: \(gridView.lineColor)")
        gridView.set(type: gridType, color: gridColor)
    }
}

typealias ButtonActions = ViewController
extension ButtonActions {
    @objc func photoTapped() {
        Instabug.logUserEvent(withName: "User adding photo")
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            showPermissionAlert()
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            Instabug.logError("Device can not display photo library")
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
        Instabug.logUserEvent(withName: "User clearing photos")
        let alert = UIAlertController(title: "Clear All Photos", message: "Are you sure you want to clear all photos?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Clear All Photos", style: .destructive) { _ in
            alert.view.isHidden = true
            self.photoView.image = nil
            self.gridView?.set(type: .none)
            self.deleteAllPhotos()
            self.loadedPhotos.removeAll()
            self.setVisibilityForButtons()
            self.setVisibilityForGrid()
            self.visibleIndex = 0
            self.updateDefaults()
            self.instructionLabel.transform = self.photoView.transform
            self.instructionLabel.isHidden = false
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            Instabug.logVerbose("User cancelled clearing photos")
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
        Instabug.logUserEvent(withName: "User swapping photos")
        visibleIndex = (visibleIndex + 1) == loadedPhotos.count ? 0 : (visibleIndex + 1)
        refreshVisiblePhoto()
        updateDefaults()
    }
    
    @IBAction func lockTapped(_ sender: UIButton) {
        let showButtons = buttonsView.isHidden
        Instabug.logUserEvent(withName: (showButtons ? "User unlocking screen" : "User locking screen"))
        lockedLabel.isHidden = showButtons
        buttonsView.isUserInteractionEnabled = showButtons
        buttonsView.isHidden = !showButtons
        lockedLabel.isUserInteractionEnabled = !showButtons
        photoScrollView.isUserInteractionEnabled = showButtons
    }
    
    @IBAction func paletteTapped(_ sender: UIButton) {
        Instabug.logUserEvent(withName: "User swapping line color")
        guard let photo = loadedPhotos[safe: visibleIndex],
        let gridView = gridView else { return }
        gridView.swapLineColor { newGridColor in
            Instabug.logVerbose("Setting color: \(newGridColor), on photo: \(photo.detail.filename)")
            photo.detail.gridColor = newGridColor.rawValue
        }
        updateDefaults()
    }
    
    @IBAction func gridTapped(_ sender: UIButton) {
        Instabug.logUserEvent(withName: "User swapping grid type")
        guard let photo = loadedPhotos[safe: visibleIndex] else { return }
        if let gridView = gridView {
            gridView.swapGrid { newGridType in
                Instabug.logVerbose("Setting type: \(newGridType), on photo: \(photo.detail.filename)")
                photo.detail.gridType = newGridType.rawValue
            }
        } else {
            addGridView()
            photo.detail.gridType = 1
        }
        
        updateDefaults()
        setVisibilityForPaletteButton()
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        Instabug.logUserEvent(withName: "User rotating photo")
        guard !loadedPhotos.isEmpty else {
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                showPermissionAlert()
            } else {
                Instabug.logVerbose("Showing no photos alert")
                let alert = UIAlertController(title: "You've got no photos", message: "Please tap the photo icon to add your first photo!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                alert.addAction(okAction)
                alert.view.isHidden = true
                present(alert, animated: false) {
                    alert.view.transform = self.photoButton.transform
                    alert.view.isHidden = false
                }
            }
            return
        }
        
        var rotation: DisplayRotation
        if photoView.transform == DisplayRotation.landscape.transform {
            setPortraitRotation()
            rotation = DisplayRotation.portrait
        } else {
            setLandscapeRotation()
            rotation = DisplayRotation.landscape
        }
        
        Instabug.logInfo("New rotation: \(rotation.rawValue)")
        updateDefaults(new: rotation)
    }
}

typealias Scaling = ViewController
extension Scaling {
    func contentScaleOfPhoto(size: CGSize) -> CGFloat {
        let widthScale = photoParentView.bounds.size.width / size.width
        let heightScale = photoParentView.bounds.size.height / size.height
        let scale = min(widthScale, heightScale)
        Instabug.logVerbose("Scale is: \(scale)")
        return scale
    }
    
    func scaleToLandscape(_ size: CGSize) -> CGRect {
        let scaledWidth = size.width * contentScaleOfPhoto(size: size)
        let scaledHeight = size.height * contentScaleOfPhoto(size: size)
        let xValue = (photoParentView.frame.width - scaledWidth) / 2
        let yValue = (photoParentView.frame.height - scaledHeight) / 2
        
        let scaledSize = CGRect(x: xValue, y: yValue, width: scaledWidth, height: scaledHeight)
        Instabug.logVerbose("Scaled size: \(size), to landscape: \(scaledSize)")
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
        Instabug.logVerbose("Scaled size: \(size), to portrait: \(scaledSize)")
        return scaledSize
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

            Instabug.logInfo("User selected photo: \(formattedFilename)")
            let photoDetail = PhotoDetail(filename: formattedFilename, timestamp: Date().timeIntervalSince1970)
            let loadedPhoto = LoadedPhoto(image: image, detail: photoDetail)
            strongSelf.addNew(loadedPhoto)
            strongSelf.setVisibilityForButtons()
        }
    }
}

typealias Grid = ViewController
extension Grid {
    func addGridView() {
        Instabug.logInfo("Adding grid view")
        gridView = PhotoGrid()
        if let gridView = gridView {
            gridView.backgroundColor = UIColor.clear
            gridView.alpha = 0.3
            photoView.addSubview(gridView)
            gridView.frame = photoView.bounds
        }
    }
}

typealias Rotation = ViewController
extension Rotation {
    func setPortraitRotation() {
        Instabug.logInfo("New Rotation: portrait")
        photoScrollView.zoomScale = 1.0
        buttons.forEach { $0.transform = DisplayRotation.portrait.transform }
        photoView.transform = DisplayRotation.portrait.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToPortrait(size)
        photoView.bounds = newSize
        gridView?.frame = photoView.bounds
        imagePickerController.view.transform = DisplayRotation.portrait.transform
    }
    
    func setLandscapeRotation() {
        Instabug.logInfo("New Rotation: landscape")
        photoScrollView.zoomScale = 1.0
        buttons.forEach { $0.transform = DisplayRotation.landscape.transform }
        photoView.transform = DisplayRotation.landscape.transform
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToLandscape(size)
        photoView.bounds = newSize
        gridView?.frame = photoView.bounds
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
            Instabug.logInfo("Showing user max number of photos alert")
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
        } else {
            Instabug.logInfo("Inserting photo at visibleIndex: \(visibleIndex)")
            loadedPhotos.insert(photo, at: visibleIndex)
            success(true)
        }
    }
    
    func save(_ loadedPhoto: LoadedPhoto) {
        guard let imageData = loadedPhoto.image.pngData() else { return }
        let savePath = defaultsDirectory.appendingPathComponent(loadedPhoto.detail.filename)
        do {
            try imageData.write(to: savePath)
        } catch {
            Instabug.logError("Failed writing image data to path: \(savePath.path)")
        }
    }
    
    func deleteStaleImageFiles() {
        deleteExtraLoadedPhotos()
        deleteExtraSavedPhotos()
    }
    
    func deleteExtraLoadedPhotos() {
        if loadedPhotos.count > numberOfPhotosToStore {
            Instabug.logVerbose("Extra loaded photos count: \(loadedPhotos.count - numberOfPhotosToStore)")
            for index in numberOfPhotosToStore..<loadedPhotos.count {
                Instabug.logVerbose("Deleting photo at index: \(index)")
                let photoToDelete = loadedPhotos[index]
                let deletePath = defaultsDirectory.appendingPathComponent(photoToDelete.detail.filename)
                do {
                    try FileManager.default.removeItem(at: deletePath)
                    loadedPhotos.remove(at: index)
                } catch {
                    Instabug.logError("Failed to remove image at path: \(deletePath.path)")
                }
            }
        }
    }
    
    func deleteExtraSavedPhotos() {
        do {
            let existingFilenames = try FileManager.default.contentsOfDirectory(at: defaultsDirectory, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }.filter { $0.contains(loadedPhotoPrefix)}
            let extraFilenames = Set(existingFilenames).subtracting(Set(loadedPhotos.map { $0.detail.filename }))
            guard !extraFilenames.isEmpty else { return }
            Instabug.logVerbose("Extra saved filenames count: \(extraFilenames)")
            for filename in extraFilenames {
                let path = defaultsDirectory.appendingPathComponent(filename)
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    Instabug.logError("Removing image data failed at path: \(path.path)")
                }
            }
        } catch {
            Instabug.logError("Failed to get contents of defaults directory: \(defaultsDirectory.path)")
        }
    }
    
    func deleteAllPhotos() {
        do {
            let existingFilenames = try FileManager.default.contentsOfDirectory(at: defaultsDirectory, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }.filter { $0.contains(loadedPhotoPrefix)}
            Instabug.logVerbose("Existing filenames count: \(existingFilenames)")
            for filename in existingFilenames {
                let path = defaultsDirectory.appendingPathComponent(filename)
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    Instabug.logError("Removing image data failed at path: \(path.path)")
                }
            }
        } catch {
            Instabug.logError("Failed to get contents of defaults directory: \(defaultsDirectory.path)")
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
        Instabug.logInfo("Updating user defaults>> visibleIndex: \(visibleIndex), rotation: \(rotation?.rawValue ?? "none"), photos count: \(details.count)")
    }
}
