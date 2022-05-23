//
//  SaveService.swift
//  InstaSave
//
//  Created by Vladyslav Yakovlev on 3/1/19.
//  Copyright © 2019 Vladyslav Yakovlev. All rights reserved.
//

import Photos
import UIKit

extension SaveService {
    
    enum Error: LocalizedError {
        
        case accessDenied
        
        case unknown
    }
}

final class SaveService {

    static var shared = SaveService()
    
//    static func saveImage(_ image: UIImage, completion: @escaping (Error?) -> ()) {
//        PHPhotoLibrary.requestAuthorization { status in
//            guard status == .authorized else {
//                return DispatchQueue.main.async {
//                    completion(.accessDenied)
//                }
//            }
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAsset(from: image)
//            }) { saved, error in
//                DispatchQueue.main.async {
//                    if saved, error == nil {
//                        completion(nil)
//                    } else {
//                        completion(.unknown)
//                    }
//                }
//            }
//        }
//    }
    
    static func saveContent(type:String, _ pathExtension:String, _ remoteUrl: URL, completion: @escaping (Error?) -> ()) {
        download(type:type, pathExtension:pathExtension, with: remoteUrl) { Url in
            guard Url != nil else {
                return DispatchQueue.main.async {
                    completion(.unknown)
                }
            }
            completion(nil)
//            var list = self.shared.load(type: type) ?? []
//            list.append(Url)
//            self.shared.save(type:type, urls: list, completion: { error in
//                completion(error)
//            })

//            writeVideoToLibrary(videoUrl) { error in
//                completion(error)
//            }
        }
    }

    //MARK: Methods
    func save(type:String, urls:[URL], completion: @escaping (Error?) -> ()) {

        let fullPath = getApplicationDirectory().appendingPathComponent(type).appendingPathComponent("\(Bundle.main.displayName ?? "Apps")_secure_file")

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: urls, requiringSecureCoding: false)
            try data.write(to: fullPath)
            debugPrint("successfully saved.")
            completion(nil)
        } catch {
           debugPrint("Failed to save...")
            completion(.unknown)
        }
    }

    func getApplicationDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func load(type:String) -> [URL]? {
//        let fullPath = getApplicationDirectory().appendingPathComponent(type).appendingPathComponent("\(Bundle.main.displayName ?? "Apps")_secure_file")
//        if let nsData = NSData(contentsOf: fullPath) {
//            do {
//
//                let data = Data(referencing:nsData)
//
//                if let loadedMeals = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Array<URL> {
//                    return loadedMeals
//                }
//            } catch {
//                print("Couldn't read file.")
//                return nil
//            }
//        }
//        return nil
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(type)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            return fileURLs
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            return nil
        }
    }
//
//    private static func writeVideoToLibrary(_ videoUrl: URL, completion: @escaping (Error?) -> ()) {
//        PHPhotoLibrary.requestAuthorization { status in
//            guard status == .authorized else {
//                return DispatchQueue.main.async {
//                    completion(.accessDenied)
//                }
//            }
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
//            }) { saved, error in
//                try? FileManager.default.removeItem(at: videoUrl)
//                DispatchQueue.main.async {
//                    if saved, error == nil {
//                        completion(nil)
//                    } else {
//                        completion(.unknown)
//                    }
//                }
//            }
//        }
//    }

    private static func download(type:String, pathExtension:String, with url: URL, completion: @escaping (URL?) -> ()) {
        DispatchQueue.main.async {
            URLSession.shared.downloadTask(with: url) { url, response, error in
                guard let tempUrl = url, error == nil else {
                    return completion(nil)
                }
                let fileManager = FileManager.default
                let applicationUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                //

                let DirPath = applicationUrl.appendingPathComponent(type)
                do
                {
    //                let fileAttr = [FileAttributeKey.protectionKey : FileProtectionType.complete]
                    try FileManager.default.createDirectory(atPath: DirPath.path, withIntermediateDirectories: true, attributes: nil)
                    print("Dir Path = \(DirPath)")
                    //
                    let FileUrl = DirPath.appendingPathComponent("\(self.shared.currentDateTime()).\(pathExtension)")
                    if fileManager.fileExists(atPath: FileUrl.path) {
                        try? fileManager.removeItem(at: FileUrl)
                    }
                    try fileManager.moveItem(at: tempUrl, to: FileUrl)
                    completion(FileUrl)
                }
                catch let error as NSError
                {
                    completion(nil)
                    print("Unable to create directory \(error.debugDescription)")
                }

            }.resume()
        }
    }

    func currentDateTime() -> String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss_SSSS"
        let dateString = df.string(from: date)
        return dateString
    }
}
