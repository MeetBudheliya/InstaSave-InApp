//
//  Helper.swift
//  InstaSave
//
//  Created by Vladyslav Yakovlev on 3/1/19.
//  Copyright © 2019 Vladyslav Yakovlev. All rights reserved.
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
    
    
    func displayToastMessage(_ message : String) {
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let toastView = UILabel()
            toastView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            toastView.textColor = UIColor.white
            toastView.textAlignment = .center
            toastView.font = UIFont.preferredFont(forTextStyle: .caption1)
            toastView.layer.cornerRadius = 15
            toastView.layer.masksToBounds = true
            toastView.text = message
            toastView.numberOfLines = 0
            toastView.alpha = 0
            toastView.translatesAutoresizingMaskIntoConstraints = false
            
            guard let window = UIApplication.shared.mainKeyWindow else {
                return
            }
            window.addSubview(toastView)
            
            let horizontalCenterContraint: NSLayoutConstraint = NSLayoutConstraint(item: toastView, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1, constant: 0)
            
            let widthContraint: NSLayoutConstraint = NSLayoutConstraint(item: toastView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 275)
            
            let verticalContraint: [NSLayoutConstraint] = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=200)-[loginView(==30)]-68-|", options: [.alignAllCenterX, .alignAllCenterY], metrics: nil, views: ["loginView": toastView])
            
            NSLayoutConstraint.activate([horizontalCenterContraint, widthContraint])
            NSLayoutConstraint.activate(verticalContraint)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                toastView.alpha = 1
            }, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double((Int64)(2 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                    toastView.alpha = 0
                }, completion: { finished in
                    toastView.removeFromSuperview()
                })
            })
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
}

//MARK: - UIApplication
extension UIApplication {
    
    public var mainKeyWindow: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first(where: { $0 is UIWindowScene })
                .flatMap { $0 as? UIWindowScene }?.windows
                .first(where: \.isKeyWindow)
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
}

