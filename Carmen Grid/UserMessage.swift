//
//  UserMessage.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

enum UserMessage {
    case noPhotos
    case noPermission
    case viewLocked
    
    var message: String {
        switch self {
        case .noPhotos:
            return """
            Welcome!
            
            To get started tap the photo icon.
            
            If you need to clear photos to start
            over again long press on the photo icon.
            """
        case .noPermission:
            return """
            Uh Oh!
            
            You have denied Carmen Grid access to your photos
            so you won't be able to load any photos into this app.
            
            Please visit your device's permission settings to allow access
            """
        case .viewLocked:
            return "View is Locked\nDouble tap to unlock"
        }
    }
    
    var alertMessage: String? {
        switch self {
        case .noPermission:
            return "You have denied access to your Photo Library. Please open your device Settings, tap on \"Privacy\" and allow Photos access for Carmen Grid."
        default: return nil
        }
    }
}
