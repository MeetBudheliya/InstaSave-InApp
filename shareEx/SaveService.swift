//
//  SaveService.swift
//  shareEx
//
//  Created by Meet's MAC on 10/08/22.
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

    static func saveContent(type:String, _ pathExtension:String, _ remoteUrl: URL, completion: @escaping (URL?, Error?) -> ()) {
        download(type:type, pathExtension:pathExtension, with: remoteUrl) { Url in
            guard Url != nil else {
                return DispatchQueue.main.async {
                    completion(nil ,.unknown)
                }
            }
            completion(Url, nil)
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
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(type)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            return fileURLs.sorted(by: {$0.creation ?? Date() > $1.creation ?? Date()})
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
            return nil
        }
    }

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
                    try FileManager.default.createDirectory(atPath: DirPath.path, withIntermediateDirectories: true, attributes: nil)
                    print("Dir Path = \(DirPath)")

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
