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
    
    var photos: [(photo: UIImage, name: String)] = []
    
    let defaultDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let nameKey = "lastPhotoName"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSavedPhotos(locatedIn: defaultDirectory)
        setUpImagePicker()
        setUpPhotoViews()
        setUpButtons()
        setUpLockLabel()
    }
}

typealias PhotoSetUp = ViewController
extension PhotoSetUp {
    func loadSavedPhotos(locatedIn directory: URL) {
        var loadedPhotos: [(photo: UIImage, name: String)] = []
        
        for suffix in 0..<3 {
            let filename = "photo\(suffix)"
            print("Attempting to retrieve \(filename)")
            let fullpath = directory.appendingPathComponent(filename)
            if let data = try? Data(contentsOf: fullpath), let photo = UIImage(data: data) {
                loadedPhotos.append((photo: photo, name: filename))
            } else {
                print("Couldn't retrieve \(filename)")
            }
        }
        
        guard !loadedPhotos.isEmpty else { return }
        
        photos = loadedPhotos.sorted { $0.name < $1.name }
        let previousName = UserDefaults.standard.string(forKey: nameKey)
        let photo = photos.filter { $0.name == previousName }.first
        if let newPhoto = photo?.photo {
            show(newPhoto)
        } else if let photo = photos.first {
            show(photo.photo)
        }
    }
    
    func replaceSavedPhotos(locatedIn directory: URL, with newPhotos: [(photo: UIImage, name: String)]) {
        for suffix in 0..<3 {
            let filename = "photo\(suffix)"
            let fullPath = directory.appendingPathComponent(filename)
            
            do {
                try FileManager.default.removeItem(at: fullPath)
                let photo = newPhotos.filter { $0.name == filename }.first
                if let image = photo?.photo {
                    save(image, to: fullPath)
                }
            } catch {
                print("Couldn't delete \(filename)")
            }
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
        swapButton.isEnabled = photos.count > 1
        
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
    
    func show(_ photo: UIImage) {
        clearGrid()
        let isPortrait = photoParentView.transform == DisplayRotation.portrait.transform
        let newSize = isPortrait ? scaleToPortrait(photo.size) : photoParentView.bounds
        photoView.image = photo
        photoView.bounds = newSize
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
        let indexOfCurrent = photos.firstIndex { photo -> Bool in
            let (image, _) = photo
            return image == photoView.image
        }
        
        guard let currentIndex = indexOfCurrent else { return }
        var newIndex = currentIndex + 1
        
        if newIndex == photos.count, let photo = photos.first?.photo {
            newIndex = 0
            show(photo)
        } else if photos.indices.contains(newIndex) {
            show(photos[newIndex].photo)
        }
        
        UserDefaults.standard.set(newIndex, forKey: nameKey)
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
            guard let photo = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
            strongSelf.show(photo)
            strongSelf.addNew(photo, to: strongSelf.defaultDirectory)
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
        guard let size = photoView.image?.size else { return }
        photoParentView.transform = DisplayRotation.portrait.transform
        let newSize = scaleToPortrait(size)
        photoView.bounds = newSize
        gridView?.frame = newSize
        buttons.forEach { $0.transform = DisplayRotation.portrait.transform }
    }
    
    func setLandscapeRotation() {
        buttons.forEach { $0.transform = DisplayRotation.landscape.transform }
        guard let size = photoView.image?.size else { return }
        photoParentView.transform = DisplayRotation.landscape.transform
        let newSize = scaleToLandscape(size)
        photoView.bounds = photoParentView.bounds
        gridView?.frame = newSize
    }
}

typealias Persistance = ViewController
extension Persistance {
    func removeLastPhoto(locatedIn directory: URL) {
        let previousIndex = photos.count - 1
        photos.remove(at: previousIndex)
        let deletePath = directory.appendingPathComponent("photo\(previousIndex)")
        do {
            try FileManager.default.removeItem(at: deletePath)
        } catch {
            print("Couldn't delete photo2")
        }
    }
    
    func addNew(_ photo: UIImage, to directory: URL) {
        let fileName = "photo0"
        let fullPath = directory.appendingPathComponent(fileName)
        if photos.count == 3 {
            removeLastPhoto(locatedIn: directory)
        }
        shiftSavedPhotos(locatedIn: directory)
        photos.insert((photo, fileName), at: 0)
        save(photo, to: fullPath)
        setVisibilityForButtons()
    }
    
    func shiftSavedPhotos(locatedIn directory: URL) {
        for index in 0..<photos.count {
            let oldPath = directory.appendingPathComponent("photo\(index)")
            let filename = (index == photos.count - 1) ? "photo0" : "photo\(index + 1)"
            let newPath = directory.appendingPathComponent(filename)
            do {
                try FileManager.default.moveItem(at: oldPath, to: newPath)
            } catch {
                print("Couldn't move saved \(filename)")
            }
        }
    }
    
    func save(_ photo: UIImage, to fullPath: URL) {
        guard let data = photo.pngData() else { return }
        do {
            try data.write(to: fullPath)
        } catch {
            print("Couldn't write \(fullPath.lastPathComponent)")
        }
    }
}
