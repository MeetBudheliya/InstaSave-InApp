//
//  ViewController.swift
//  share
//
//  Created by Meet's MAC on 17/05/22.
//

import UIKit
import WebKit

let suiteName = "group.com.meet.InstaSave.Extension"
let keyName = "shareURL"
let videos = "VideoList"
let images = "ImageList"
enum MediaType: String{
    case video = "mp4"
    case image = "jpg"
}

class ViewController: UIViewController{
    
    var sharedURL = URL(string: UIPasteboard.general.string ?? "")
    var loader = UIAlertController()
    var carousel_media = [Json]()
    var timer = Timer()
    var carousel_media_index = 0
    @IBOutlet weak var web: WKWebView!
    @IBOutlet weak var overlayview: UIView!
    @IBOutlet weak var textFieldPase: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.


        self.title = Bundle.main.displayName
        loader = self.loader()

        self.overlayview.isHidden = true
        self.web.navigationDelegate = self
        self.textFieldPase.delegate = self


        if let url = UserDefaults(suiteName: suiteName)?.url(forKey: keyName){
            self.sharedURL = url
            print("Shared URL Found : " + (self.sharedURL?.absoluteString ?? "Nil"))

        }else{
            let paste = UIPasteboard.general.string ?? ""
            self.sharedURL = URL(string: paste)
        }

        self.web.load(URLRequest(url: self.sharedURL ?? URL(string: "https://i.pinimg.com/564x/49/e5/8d/49e58d5922019b8ec4642a2e2b9291c2.jpg")!))
        
    }
    
    @IBAction func galleryButtonClicked(_ sender: UIBarButtonItem) {
        let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SavedViewController") as! SavedViewController
        nextVC.modalTransitionStyle = .crossDissolve
        nextVC.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
    @IBAction func reloadButtonClicked(_ sender: UIButton) {
        self.viewDidLoad()
    }
    
    
}

//MARK: - TextFied delegate setup
extension ViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.text != nil && textField.text != ""{
            loader = self.loader()
            self.sharedURL = URL(string: textField.text!)
            self.web.load(URLRequest(url: self.sharedURL ?? URL(string: "https://i.pinimg.com/564x/49/e5/8d/49e58d5922019b8ec4642a2e2b9291c2.jpg")!))
            return true
        }else{
            self.displayToastMessage("paste any url here")
            return false
        }
    }
}

//MARK: - Webview delegate setup
extension ViewController: WKNavigationDelegate{
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        debugPrint("HOST : \(navigationAction.request.url?.host ?? "NIL")")
        debugPrint("Requested URL : \(navigationAction.request.url?.absoluteString ?? "NIL")")
        if let host = navigationAction.request.url?.host {
            if host == "www.instagram.com" {
                decisionHandler(.allow)
                if navigationAction.request.url?.absoluteString.contains("https://www.instagram.com/accounts/onetap/") ?? false{
                    self.overlayview.isHidden = true
                    self.stopLoader(loader: self.loader)
                    self.displayToastMessage("Login successfully...")
                }
                return
            }
        }
        self.stopLoader(loader: self.loader)
        self.alert(msg: "Please enter instagram url")
        decisionHandler(.cancel)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView content loaded.")
        
        //        self.web.load(URLRequest(url: URL(string: "www.instagram.com")!))
        guard let activeLink = self.checkLink(self.sharedURL?.absoluteString ?? "") else {
            self.stopLoader(loader: self.loader)
            self.displayToastMessage("Invalid Link")
            return
        }
        self.textFieldPase.text = self.sharedURL?.absoluteString
        self.getMediaPost(with: activeLink)
        UserDefaults(suiteName: suiteName)?.set(nil, forKey: keyName)
    }
}

//MARK: - InstaSave
extension ViewController{
    
    func checkLink(_ link: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "^https://(www.)?instagram.com/.*/", options: .caseInsensitive)
        let matches = regex.matches(in: link, options: [], range: NSMakeRange(0, link.count))
        guard !matches.isEmpty else {
            self.stopLoader(loader: self.loader)
            self.displayToastMessage("Invalid Link")
            return nil
        }
        if let activeLink = link.components(separatedBy: "?").first {
            return activeLink
        } else {
            self.stopLoader(loader: self.loader)
            self.displayToastMessage("Invalid Link")
            return nil
        }
    }
    
    func getMediaPost(with link: String) {
        getJson(link) { json in
            guard let json = json else {
                self.stopLoader(loader: self.loader)
                self.displayToastMessage("data not found, please try again")
                return
            }
            self.parseJson(json)
        }
    }
    
    func getJson(_ link: String, completion: @escaping (Json?) -> ()) {
        let url = URL(string: "\(link)?__a=1")!
        
        web.configuration.websiteDataStore.httpCookieStore.getAllCookies({ cookies in
            var c = [HTTPCookie]()
            for cookie in cookies {
                //...
                print(cookie)
                c.append(cookie)
            }
            // First
            let jar = HTTPCookieStorage.shared
            jar.setCookies(c, for: url, mainDocumentURL: url)
            
            // Then
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request){ data, response, error in
                
                guard !(response?.url?.absoluteString.contains("www.instagram.com/accounts/login") ?? true) else{
                    self.stopLoader(loader: self.loader)
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: Bundle.main.displayName, message: "Unable to get video, you have to login at first time", preferredStyle: .alert)
                        let loginAction = UIAlertAction(title: "Login", style: .default) { _Arg in
                            self.overlayview.isHidden = false
                        }
                        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { _Arg in
                            //
                        }
                        alert.addAction(loginAction)
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                guard let data = data, error == nil else {
                    self.stopLoader(loader: self.loader)
                    if error != nil{
                        self.displayToastMessage(error?.localizedDescription ?? "something went wrong, please try again")
                    }else{
                        self.displayToastMessage("data not found, please try again")
                    }
                    return completion(nil)
                }
                if let json = (try? JSONSerialization.jsonObject(with: data)) as? Json {
                    completion(json)
                } else {
                    self.stopLoader(loader: self.loader)
                    completion(nil)
                }
            }.resume()
        })
        
    }

    //MARK: - Parse data into json and call download
    func parseJson(_ json: Json) {
        
        guard let items = json["items"] as? [Json] else{
            self.stopLoader(loader: self.loader)
            self.displayToastMessage("please try again or use another url")
            return
        }
        guard let item = items.first else{
            print("Items not found")
            self.stopLoader(loader: self.loader)
            self.displayToastMessage("please try again or use another url")
            return
        }
        
        let media_type = item["media_type"] as? Int ?? 0 // 1.Image 2.Video 8.carousel_media
        switch media_type{
        case 1:
            print("Image")
            if let image_versions2 = item["image_versions2"] as? Json, var candidates = image_versions2["candidates"] as? [Json]{
                print("Success : \(image_versions2)")
                
                DispatchQueue.main.async {
                    self.stopLoader(loader: self.loader)
                    
                    if candidates.count == 1{
                        let c = candidates.first as NSDictionary?
                        let imageUrlString = c?.value(forKey: "url") as? String ?? ""
                        guard let url = URL(string: imageUrlString)else{
                            self.stopLoader(loader: self.loader)
                            self.displayToastMessage("data not found, please try again")
                            return
                        }
                        
                        SaveService.saveContent(type: images, MediaType.image.rawValue, url) { error in
                            if let error = error {
                                switch error {
                                case .accessDenied :
                                    self.stopLoader(loader: self.loader)
                                    self.alert(msg: "Please allow photos access from settings to save media in album")
                                case .unknown :
                                    self.stopLoader(loader: self.loader)
                                    self.displayToastMessage("Having some issue to save, please try again")
                                }
                            } else {
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Image Downloaded")
                                DispatchQueue.main.async {
                                    self.textFieldPase.text = ""
                                }
                            }
                        }
                    }else{
                        let qualityAlert = UIAlertController(title: "Insta Content Download", message: "Select media quality", preferredStyle: .actionSheet)
                        candidates = candidates.sorted { item1, item2 in
                            let first = item1 as NSDictionary
                            let second = item2 as NSDictionary
                            let firstWidth = first.value(forKey: "width") as? Int ?? 0
                            let secondWidth = second.value(forKey: "width") as? Int ?? 0
                            return firstWidth > secondWidth
                        }
                        for videoV in candidates{
                            let v = videoV as NSDictionary
                            let height = v.value(forKey: "height") ?? "-"
                            let width = v.value(forKey: "width") ?? "-"
                            
                            let actionBTN = UIAlertAction(title: "\(width)*\(height)", style: .default) { _ in
                                self.loader = self.loader()
                                
                                let imageUrlString = v.value(forKey: "url") as? String ?? ""
                                guard let url = URL(string: imageUrlString)else{
                                    self.stopLoader(loader: self.loader)
                                    self.displayToastMessage("Content data not found")
                                    return
                                }
                                
                                SaveService.saveContent(type: images, MediaType.image.rawValue, url) { error in
                                    if error != nil {
                                        switch error {
                                        case .accessDenied :
                                            self.stopLoader(loader: self.loader)
                                            self.alert(msg: "Please allow photos access from settings to save media in album")
                                        case .unknown :
                                            self.stopLoader(loader: self.loader)
                                            self.displayToastMessage("Having some issue to save, please try again")
                                        case .none:
                                            self.stopLoader(loader: self.loader)
                                            self.displayToastMessage("Content data not found, please try with another link")
                                        }
                                    } else {
                                        self.stopLoader(loader: self.loader)
                                        self.alert(msg: "Image Downloaded")
                                        DispatchQueue.main.async {
                                            self.textFieldPase.text = ""
                                        }
                                    }
                                }
                            }
                            qualityAlert.addAction(actionBTN)
                        }
                        let cancel = UIAlertAction(title: "Cancel", style: .default) { _ in
                            //
                        }
                        qualityAlert.addAction(cancel)
                        self.presentedViewController?.dismiss(animated: true, completion: nil)
                        self.present(qualityAlert, animated: true, completion: nil)
                    }
                }
            }else{
                self.stopLoader(loader: self.loader)
                self.displayToastMessage("Content data not found, please try with another link")
            }
        case 2:
            print("Video")
            if var video_versions = item["video_versions"] as? [Json]{
                print("Success : \(video_versions)")
                
                DispatchQueue.main.async {
                    self.stopLoader(loader: self.loader)
                    if video_versions.count == 1{
                        let v = video_versions.first as NSDictionary?
                        let videoUrlString = v?.value(forKey: "url") as? String ?? ""
                        guard let url = URL(string: videoUrlString) else{
                            self.stopLoader(loader: self.loader)
                            self.alert(msg: "Content data not found")
                            return
                        }
                        SaveService.saveContent(type: videos, MediaType.video.rawValue, url) { error in
                            if let error = error {
                                switch error {
                                case .accessDenied :
                                    self.stopLoader(loader: self.loader)
                                    self.alert(msg: "Please allow photos access from settings to save media in album")
                                case .unknown :
                                    self.stopLoader(loader: self.loader)
                                    self.displayToastMessage("Having some issue to save, please try again")
                                }
                            } else {
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Video Downloaded")
                                DispatchQueue.main.async {
                                    self.textFieldPase.text = ""
                                }
                            }
                        }
                    }else{
                        let qualityAlert = UIAlertController(title: "Insta Content Download", message: "Select media quality", preferredStyle: .actionSheet)
                        
                        video_versions = video_versions.sorted { item1, item2 in
                            let first = item1 as NSDictionary
                            let second = item2 as NSDictionary
                            let firstWidth = first.value(forKey: "width") as? Int ?? 0
                            let secondWidth = second.value(forKey: "width") as? Int ?? 0
                            return firstWidth > secondWidth
                        }
                        for videoV in video_versions{
                            let v = videoV as NSDictionary
                            let height = v.value(forKey: "height") ?? "-"
                            let width = v.value(forKey: "width") ?? "-"
                            
                            let actionBTN = UIAlertAction(title: "\(width)*\(height)", style: .default) { _ in
                                self.loader = self.loader()
                                
                                let videoUrlString = v.value(forKey: "url") as? String ?? ""
                                guard let url = URL(string: videoUrlString) else{
                                    self.stopLoader(loader: self.loader)
                                    self.alert(msg: "Content data not found")
                                    return
                                }
                                SaveService.saveContent(type: videos, MediaType.video.rawValue, url) { error in
                                    if let error = error {
                                        switch error {
                                        case .accessDenied :
                                            self.stopLoader(loader: self.loader)
                                            self.alert(msg: "Please allow photos access from settings to save media in album")
                                        case .unknown :
                                            self.stopLoader(loader: self.loader)
                                            self.displayToastMessage("Having some issue to save, please try again")
                                        }
                                    } else {
                                        self.stopLoader(loader: self.loader)
                                        self.alert(msg: "Video Downloaded")
                                        DispatchQueue.main.async {
                                            self.textFieldPase.text = ""
                                        }
                                    }
                                }
                            }
                            
                            qualityAlert.addAction(actionBTN)
                            
                        }
                        let cancel = UIAlertAction(title: "Cancel", style: .default) { _ in
                            //
                        }
                        qualityAlert.addAction(cancel)
                        self.presentedViewController?.dismiss(animated: true, completion: nil)
                        self.present(qualityAlert, animated: true, completion: nil)
                    }
                }
            }else{
                self.stopLoader(loader: self.loader)
                self.displayToastMessage("Content data not found, please try with another link")
            }
        case 8:
            print("CAROUSEL_MEDIA")
            if let carousel_media = item["carousel_media"] as? [Json]{
                self.carousel_media = carousel_media
                self.carousel_media_index = 0
                self.downloadCarousolMedia()

            }else{
                self.stopLoader(loader: self.loader)
                self.displayToastMessage("Content data not found, please try with another link")
            }
        default:
            self.displayToastMessage("unsupported media, please try with another link")
        }
    }


    //MARK: - Recursive function for download
    func downloadCarousolMedia(){
        if carousel_media.count > carousel_media_index{
            let media = carousel_media[carousel_media_index]
            let mediaType = media["media_type"] as? Int ?? 0

            carousel_media_index += 1

            switch mediaType{
            case 1:
                print("Image")
                if let image_versions2 = media["image_versions2"] as? Json, let candidates = image_versions2["candidates"] as? [Json]{
                    print("Success : \(image_versions2)")

                    self.stopLoader(loader: self.loader)

                    let c = candidates.first as NSDictionary?
                    let imageUrlString = c?.value(forKey: "url") as? String ?? ""
                    guard let url = URL(string: imageUrlString)else{
                        self.stopLoader(loader: self.loader)
                        self.alert(msg: "Content data not found")
                        return
                    }

                    SaveService.saveContent(type: images, MediaType.image.rawValue, url) { error in
                        if let error = error {
                            switch error {
                            case .accessDenied :
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Please allow photos access from settings to save media in album")
                            case .unknown :
                                self.stopLoader(loader: self.loader)
                                self.displayToastMessage("Having some issue to save, please try again")
                            }
                        } else {
                            if self.carousel_media.count == self.carousel_media_index{
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Downloaded...")
                                DispatchQueue.main.async {
                                    self.textFieldPase.text = ""
                                }
                            }else{
                                self.downloadCarousolMedia()
                            }
                        }
                    }
                }else{
                    self.stopLoader(loader: self.loader)
                    self.displayToastMessage("Content data not found, please try with another link")
                }
            case 2:
                print("Video")
                if let video_versions = media["video_versions"] as? [Json]{
                    print("Success : \(video_versions)")

                    self.stopLoader(loader: self.loader)

                    let v = video_versions.first as NSDictionary?
                    let videoUrlString = v?.value(forKey: "url") as? String ?? ""
                    guard let url = URL(string: videoUrlString) else{
                        self.stopLoader(loader: self.loader)
                        self.alert(msg: "Content data not found")
                        return
                    }
                    SaveService.saveContent(type: videos, MediaType.video.rawValue, url) { error in
                        if let error = error {
                            switch error {
                            case .accessDenied :
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Please allow photos access from settings to save media in album")
                            case .unknown :
                                self.stopLoader(loader: self.loader)
                                self.displayToastMessage("Having some issue to save, please try again")
                            }
                        } else {
                            if self.carousel_media.count == self.carousel_media_index{
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Downloaded...")
                                DispatchQueue.main.async {
                                    self.textFieldPase.text = ""
                                }
                            }else{
                                self.downloadCarousolMedia()
                            }
                        }
                    }
                }else{
                    self.stopLoader(loader: self.loader)
                    self.displayToastMessage("Content data not found, please try with another link")
                }
            default:
                self.displayToastMessage("unsupported media, please try with another link")
            }
        }
    }
}
