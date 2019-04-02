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
    
    @IBOutlet weak var photoParentView: TransparentView!
    @IBOutlet weak var photoScrollView: UIScrollView!
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
        
        photoView.transform = landscapeRotation
        
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
        let photoLoaded = (photoView.image != nil)
        let mainAlpha = photoLoaded ? 1.0 : 0.0
        lockButton.alpha = CGFloat(mainAlpha)
        lockButton.isUserInteractionEnabled = photoLoaded
        gridButton.alpha = CGFloat(mainAlpha)
        gridButton.isUserInteractionEnabled = photoLoaded
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
        let widthScale = photoView.frame.size.width / width
        let heightScale = photoView.frame.size.height / height
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
    
    func boundsForGridView(using size: CGSize) -> CGRect {
        let scaledWidth = scaledWidthOfPhoto(size: size)
        let scaledHeight = scaledHeightOfPhoto(size: size)
        
        let xValue = (photoView.frame.width - scaledWidth) / 2
        let yValue = (photoView.frame.height - scaledHeight) / 2
        
        return CGRect(x: xValue, y: yValue, width: scaledWidth, height: scaledHeight)
    }
    
    func addGridView() {
        guard let size = photoView.image?.size else { return }
        print(size)
        gridView = PhotoGrid()
        if let gridView = gridView {
            let bounds = boundsForGridView(using: size)
            gridView.frame = bounds
            print(bounds)
            gridView.backgroundColor = UIColor.clear
            gridView.alpha = 0.3
            photoView.addSubview(gridView)
        }
    }
    
    func setPortraitRotation() {
        guard let size = photoView.image?.size else { return }
        print("set portrait with size: \(size)")
        let scale = size.height / size.width
        var newWidth = photoParentView.frame.height
        var newHeight = newWidth * scale
        if scale >= 1.0 { // Portrait oriented photo
            newHeight = photoParentView.frame.width
            newWidth = newHeight / scale
        }
        
        let xValue = (photoParentView.frame.width - newWidth) / 2
        let yValue = (photoParentView.frame.height - newHeight) / 2
        let newBounds = CGRect(x: xValue, y: yValue, width: newWidth, height: newHeight)
        photoView.bounds = newBounds
        gridView?.bounds = boundsForGridView(using: size)
        photoView.transform = portraitRotation
        buttons.forEach { $0.transform = portraitRotation }
    }
    
    func setLandscapeRotation() {
        buttons.forEach { $0.transform = landscapeRotation }
        
        guard let size = photoView.image?.size else { return }
        photoView.bounds = photoParentView.bounds
        photoView.transform = landscapeRotation
        gridView?.frame = boundsForGridView(using: size)
    }
    
    @IBAction func rotateTapped(_ sender: UIButton) {
        if photoView.transform == landscapeRotation {
            setPortraitRotation()
        } else {
            setLandscapeRotation()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:  [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.clearGrid()
            let image = info[UIImagePickerController.InfoKey.originalImage]
            print(strongSelf.photoParentView.bounds)
            strongSelf.photoView.frame = strongSelf.photoParentView.bounds
            strongSelf.photoView.image = image as? UIImage
            strongSelf.setVisibilityForLockAndGridButtons()
        }
    }
    
    func clearGrid() {
        gridView?.removeFromSuperview()
        gridView = nil
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return photoView
    }
}
