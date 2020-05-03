//
//  Persistance.swift
//  Carmen Grid
//
//  Created by Abbey Bobabbey on 2020-05-02.
//  Copyright © 2020 Abbey Jackson. All rights reserved.
//

import UIKit

class Persistance {
    let defaultsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var loadedPhotos: [LoadedPhoto] = []
    var visibleIndex: Int = 0
    
    let loadedPhotosKey = "loadedPhotos"
    let visibleIndexKey = "visibleIndex"
    let displayRotationKey = "displayRotation"
    let numberOfPhotosToStore = 3
    let loadedPhotoPrefix = "loaded-"
    
    func retrieveSavedPhotos() {
        let decoder = JSONDecoder()
        guard let detailsData = UserDefaults.standard.array(forKey: loadedPhotosKey) as? [Data], !detailsData.isEmpty else {
            Log.logInfo("SETUP>> Number of previously saved photos: none")
            return
        }
        Log.logInfo("SETUP>> Number of previously saved photos: \(detailsData.count)")
        for detailData in detailsData {
            if let detail = try? decoder.decode(PhotoDetail.self, from: detailData) {
                let path = defaultsDirectory.appendingPathComponent(detail.filename)
                if let imageData = try? Data(contentsOf: path), let image = UIImage(data: imageData) {
                    let loadedPhoto = LoadedPhoto(image: image, detail: detail)
                    loadedPhotos.append(loadedPhoto)
                } else {
                    Log.logError("SETUP>> Failed retrieving previously saved photo at: \(path)")
                }
            } else {
                Log.logError("SETUP>> Failed decoding of previously saved photo details data")
            }
        }
        loadedPhotos.sortByTimestamp()
        deleteStaleImageFiles()
    }
    
    func addNew(_ photo: LoadedPhoto, photoLimitAction: () -> (Bool)) {
        
        if let matchingIndex = loadedPhotos.firstIndex(where: { $0.detail.filename == photo.detail.filename }),
            matchingIndex < numberOfPhotosToStore {
            loadedPhotos[matchingIndex].detail.timestamp = photo.detail.timestamp
            loadedPhotos.sortByTimestamp()
            visibleIndex = 0
        } else if loadedPhotos.count == numberOfPhotosToStore {
            Log.logInfo("Showing user max number of photos alert")
            if photoLimitAction() {
                self.loadedPhotos[self.visibleIndex] = photo
            }
        } else {
            Log.logInfo("Inserting photo at visibleIndex: \(visibleIndex)")
            loadedPhotos.insert(photo, at: visibleIndex)
        }
        
        self.save(photo)
        self.deleteStaleImageFiles()
        self.updateDefaults()
    }
    
    private func save(_ loadedPhoto: LoadedPhoto) {
        guard let imageData = loadedPhoto.image.pngData() else { return }
        let savePath = defaultsDirectory.appendingPathComponent(loadedPhoto.detail.filename)
        do {
            try imageData.write(to: savePath)
        } catch {
            Log.logError("Failed writing image data to path: \(savePath.path)")
        }
    }
    
    private func deleteStaleImageFiles() {
        deleteExtraLoadedPhotos()
        deleteExtraSavedPhotos()
    }
    
    private func deleteExtraLoadedPhotos() {
        if loadedPhotos.count > numberOfPhotosToStore {
            Log.logVerbose("Extra loaded photos count: \(loadedPhotos.count - numberOfPhotosToStore)")
            for index in numberOfPhotosToStore..<loadedPhotos.count {
                Log.logVerbose("Deleting photo at index: \(index)")
                let photoToDelete = loadedPhotos[index]
                let deletePath = defaultsDirectory.appendingPathComponent(photoToDelete.detail.filename)
                do {
                    try FileManager.default.removeItem(at: deletePath)
                    loadedPhotos.remove(at: index)
                } catch {
                    Log.logError("Failed to remove image at path: \(deletePath.path)")
                }
            }
        }
    }
    
    func deleteExtraSavedPhotos() {
        do {
            let existingFilenames = try FileManager.default.contentsOfDirectory(at: defaultsDirectory, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }.filter { $0.contains(loadedPhotoPrefix)}
            let extraFilenames = Set(existingFilenames).subtracting(Set(loadedPhotos.map { $0.detail.filename }))
            guard !extraFilenames.isEmpty else { return }
            Log.logVerbose("Extra saved filenames count: \(extraFilenames)")
            for filename in extraFilenames {
                let path = defaultsDirectory.appendingPathComponent(filename)
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    Log.logError("Removing image data failed at path: \(path.path)")
                }
            }
        } catch {
            Log.logError("Failed to get contents of defaults directory: \(defaultsDirectory.path)")
        }
    }
    
    func deleteAllPhotos() {
        do {
            let existingFilenames = try FileManager.default.contentsOfDirectory(at: defaultsDirectory, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }.filter { $0.contains(loadedPhotoPrefix)}
            Log.logVerbose("Existing filenames count: \(existingFilenames)")
            for filename in existingFilenames {
                let path = defaultsDirectory.appendingPathComponent(filename)
                do {
                    try FileManager.default.removeItem(at: path)
                } catch {
                    Log.logError("Removing image data failed at path: \(path.path)")
                }
            }
        } catch {
            Log.logError("Failed to get contents of defaults directory: \(defaultsDirectory.path)")
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
        Log.logInfo("Updating user defaults>> visibleIndex: \(visibleIndex), rotation: \(rotation?.rawValue ?? "none"), photos count: \(details.count)")
    }
}
