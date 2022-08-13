//
//  Helper.swift
//  shareEx
//
//  Created by Meet's MAC on 10/08/22.
//



import UIKit
import AVFoundation

typealias Json = [String : Any]

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

//MARK: - UIColor
extension UIColor {

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }

    convenience init(hex: String, alpha: CGFloat = 1) {
        self.init(r: CGFloat((Int(hex, radix: 16)! >> 16) & 0xFF), g: CGFloat((Int(hex, radix: 16)! >> 8) & 0xFF), b: CGFloat((Int(hex, radix: 16)!) & 0xFF), a: alpha)
    }
}

//MARK: - URLSession
extension URLSession {

    class func getImage(url: URL, completion: @escaping (UIImage?) -> ()) {
        shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, error == nil {
                    completion(UIImage(data: data))
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
}

//MARK: - Bundle
extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}

//MARK: - String
extension String {

    var url: URL? {
        return URL(string: self)
    }
}

//MARK: - UIViewController
extension UIViewController{

    func makeThumbFromVideo(_ url:URL) -> UIImage {
        let asset = AVURLAsset(url: url)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        guard let cgImage = (try? imgGenerator.copyCGImage(at: CMTime(value: 0, timescale: 1), actualTime: nil)) else {
            return UIImage(named: "download")!
        }
        return UIImage(cgImage: cgImage)
    }

    func makeThumbFromImage(_ url:URL) -> UIImage {
        do{
            let imgData = try Data(contentsOf: url)
            return UIImage(data: imgData) ?? UIImage(named: "download")!
        }catch{
            return UIImage(named: "download")!
        }
    }

    func alert(msg:String){

        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            let alert = UIAlertController(title: "Insta Save", message: msg, preferredStyle: .alert)
            let ohkAction = UIAlertAction(title: "OK", style: .default) { _Arg in
                //
            }
            alert.addAction(ohkAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    func loader() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        DispatchQueue.main.async {
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.large
            loadingIndicator.startAnimating()
            alert.view.addSubview(loadingIndicator)
            self.present(alert, animated: true, completion: nil)
        }
        return alert
    }

    func stopLoader(loader : UIAlertController) {
        DispatchQueue.main.async {
            loader.dismiss(animated: true, completion: nil)
        }
    }
}

//MARK: - URL
extension URL{
    func convertToImage() -> UIImage?{
        do{
            let data = try Data(contentsOf: self)
            return UIImage(data: data)
        }catch{
            return UIImage()
        }
    }

    /// The time at which the resource was created.
    /// This key corresponds to an Date value, or nil if the volume doesn't support creation dates.
    /// A resource’s creationDateKey value should be less than or equal to the resource’s contentModificationDateKey and contentAccessDateKey values. Otherwise, the file system may change the creationDateKey to the lesser of those values.
    var creation: Date? {
        get {
            return (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.creationDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
    /// The time at which the resource was most recently modified.
    /// This key corresponds to an Date value, or nil if the volume doesn't support modification dates.
    var contentModification: Date? {
        get {
            return (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.contentModificationDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
    /// The time at which the resource was most recently accessed.
    /// This key corresponds to an Date value, or nil if the volume doesn't support access dates.
    ///  When you set the contentAccessDateKey for a resource, also set contentModificationDateKey in the same call to the setResourceValues(_:) method. Otherwise, the file system may set the contentAccessDateKey value to the current contentModificationDateKey value.
    var contentAccess: Date? {
        get {
            return (try? resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
        }
        // Beginning in macOS 10.13, iOS 11, watchOS 4, tvOS 11, and later, contentAccessDateKey is read-write. Attempts to set a value for this file resource property on earlier systems are ignored.
        set {
            var resourceValues = URLResourceValues()
            resourceValues.contentAccessDate = newValue
            try? setResourceValues(resourceValues)
        }
    }

}
