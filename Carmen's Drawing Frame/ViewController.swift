//
//  ViewController.swift
//  Carmen's Drawing Frame
//
//  Created by Abbey Jackson on 2019-03-26.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollParentView: TransparentView!
    @IBOutlet weak var photoScrollView: UIScrollView!
    @IBOutlet weak var photoParentView: UIView!
    @IBOutlet weak var photoView: UIImageView!
    
    @IBOutlet weak var lockedLabel: UILabel!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var paletteButton: UIButton!
    @IBOutlet weak var gridButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet var buttons: [UIButton]!
    
    var gridView: PhotoGrid?
    var imagePickerController = UIImagePickerController()
    
    let portraitRotation = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
    let landscapeRotation = CGAffineTransform(rotationAngle: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.modalPresentationStyle = UIModalPresentationStyle.currentContext
        imagePickerController.delegate = self as UINavigationControllerDelegate & UIImagePickerControllerDelegate
        photoScrollView.delegate = self
        
        photoScrollView.minimumZoomScale = 1
        photoScrollView.maximumZoomScale = 10
        
        photoParentView.transform = landscapeRotation
        
        setUpButtons()
        
        lockedLabel.text = "View\nis\nLocked\nDouble\ntap\nto\nunlock"
        let unlockGesture = UITapGestureRecognizer(target: self, action: #selector(lockTapped(_:)))
        unlockGesture.numberOfTapsRequired = 2
        lockedLabel.addGestureRecognizer(unlockGesture)
    }
    
    func setUpButtons() {
        let minPadding = CGFloat(4)
        let buttonSize = photoButton.bounds.width - minPadding
        let xInset = minPadding / 2
        let yInset = (photoButton.bounds.height - buttonSize) / 2
        
        let photoImage = UIImage(named: "photo")?.withRenderingMode(.alwaysTemplate)
        photoButton.setImage(photoImage, for: .normal)
        photoButton.tintColor = UIColor.gray
        photoButton.imageEdgeInsets = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
        
        let lockImage = UIImage(named: "lock")?.withRenderingMode(.alwaysTemplate)
        lockButton.setImage(lockImage, for: .normal)
        lockButton.tintColor = UIColor.gray
        lockButton.imageEdgeInsets = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
        
        let paletteImage = UIImage(named: "palette")?.withRenderingMode(.alwaysTemplate)
        paletteButton.setImage(paletteImage, for: .normal)
        paletteButton.tintColor = UIColor.gray
        paletteButton.imageEdgeInsets = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
        
        let gridImage = UIImage(named: "grid")?.withRenderingMode(.alwaysTemplate)
        gridButton.setImage(gridImage, for: .normal)
        gridButton.tintColor = UIColor.gray
        gridButton.imageEdgeInsets = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
        
        let rotateImage = UIImage(named: "rotate")?.withRenderingMode(.alwaysTemplate)
        rotateButton.setImage(rotateImage, for: .normal)
        rotateButton.tintColor = UIColor.gray
        rotateButton.imageEdgeInsets = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
        
        setVisibilityForLockAndGridButtons()
    }
    
    func setVisibilityForLockAndGridButtons() {
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

    @IBAction func photoTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "Your device can not display the photo library", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func lockTapped(_ sender: UIButton) {
       let showButtons = buttonsView.isHidden
        buttonsView.isUserInteractionEnabled = showButtons
        buttonsView.isHidden = !showButtons
        lockedLabel.isUserInteractionEnabled = !showButtons
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
        print("parent: \(photoParentView.frame) bounds: \(photoParentView.bounds)")
        let scale = size.height / size.width
        var newWidth = photoParentView.bounds.height
        var newHeight = newWidth * scale
        if scale >= 1.0 { // Portrait oriented photo
            newHeight = photoParentView.bounds.width
            newWidth = newHeight / scale
        }
        print("newWidth: \(newWidth) newHeight: \(newHeight)")
        
        let xValue = (photoParentView.bounds.width - newWidth) / 2
        let yValue = (photoParentView.bounds.height - newHeight) / 2
        
        let scaledSize = CGRect(x: xValue, y: yValue, width: newWidth, height: newHeight)
        return scaledSize
    }
    
    func addGridView() {
        guard let size = photoView.image?.size else { return }
        gridView = PhotoGrid()
        if let gridView = gridView {
            let isPortrait = photoView.transform == portraitRotation
            let newSize = isPortrait ? scaleToPortrait(size) : scaleToLandscape(size)
            gridView.backgroundColor = UIColor.clear
            gridView.alpha = 0.3
            photoParentView.addSubview(gridView)
            gridView.frame = newSize
        }
    }
    
    func setPortraitRotation() {
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToPortrait(size)
        photoParentView.transform = portraitRotation
        print("portrait: \(newSize)")
        print("parent rotated: \(photoParentView.frame)")
        photoView.bounds = newSize
        gridView?.bounds = newSize
        buttons.forEach { $0.transform = portraitRotation }
    }
    
    func setLandscapeRotation() {
        buttons.forEach { $0.transform = landscapeRotation }
        
        guard let size = photoView.image?.size else { return }
        let newSize = scaleToLandscape(size)
        print("landscape: \(newSize)")
        photoView.bounds = photoParentView.bounds
        photoParentView.transform = landscapeRotation
        gridView?.frame = newSize
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        if photoParentView.transform == landscapeRotation {
            setPortraitRotation()
        } else {
            setLandscapeRotation()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:  [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.clearGrid()
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
            let isPortrait = strongSelf.photoParentView.transform == strongSelf.portraitRotation
            let newSize = isPortrait ? strongSelf.scaleToPortrait(image.size) : strongSelf.photoParentView.bounds
            print("parent at image picked: \(strongSelf.photoParentView.frame) bounds: \(strongSelf.photoParentView.bounds)")
            print("image picked: \(newSize)")
            strongSelf.photoView.image = image
            strongSelf.photoView.bounds = newSize
            strongSelf.setVisibilityForLockAndGridButtons()
        }
    }
    
    func clearGrid() {
        gridView?.removeFromSuperview()
        gridView = nil
    }
    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return photoView
//    }
    
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        let currentTranform = photoView.transform
//        photoView.transform = CGAffineTransform(scaleX: scale, y: <#T##CGFloat#>)
//    }
}
