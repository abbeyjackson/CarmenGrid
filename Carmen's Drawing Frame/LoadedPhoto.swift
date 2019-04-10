//
//  LoadedPhoto.swift
//  Carmen's Drawing Frame
//
//  Created by Abbey Jackson on 2019-04-07.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import UIKit

class LoadedPhoto {
    let image: UIImage
    var detail: PhotoDetail
    
    init(image: UIImage, detail: PhotoDetail) {
        self.image = image
        self.detail = detail
    }
}
