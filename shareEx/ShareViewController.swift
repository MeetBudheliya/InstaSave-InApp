//
//  ShareViewController.swift
//  shareEx
//
//  Created by Meet's MAC on 17/05/22.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import WebKit

let suiteName = "group.com.meet.InstaSave.Extension"
let keyName = "shareURL"
let videos = "VideoList"
let images = "ImageList"
enum MediaType: String{
    case video = "mp4"
    case image = "jpg"
}

class ShareViewController: UIViewController {

    var shareURL = URL(string: "https://www.google.co.in/")
    var loader = UIAlertController()
    var carousel_media = [Json]()
    var timer = Timer()
    var carousel_media_index = 0

    @IBOutlet weak var img_thumb: UIImageView!
    @IBOutlet weak var lbl_titile: UILabel!
    @IBOutlet weak var lbl_desc: UILabel!
    @IBOutlet weak var web: WKWebView!
    @IBOutlet weak var overlayview: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()


        let extensionItem = extensionContext?.inputItems[0] as! NSExtensionItem
        var contentTypeURL = ""

        if #available(iOS 14.0, *) {
            contentTypeURL = UTType.url.identifier as String
        } else {
            contentTypeURL = kUTTypeURL as String
        }

        for attachment in extensionItem.attachments ?? []{
            if attachment.hasItemConformingToTypeIdentifier("public.url") {
                attachment.loadItem(forTypeIdentifier: contentTypeURL, options: nil, completionHandler: { (results, error) in
                    let url = results as? URL
                    self.shareURL = url
                    print("URL : \(self.shareURL?.absoluteString ?? "")")

                    self.overlayview.isHidden = true
                    self.web.navigationDelegate = self

                    self.web.load(URLRequest(url: self.shareURL ?? URL(string: "https://i.pinimg.com/564x/49/e5/8d/49e58d5922019b8ec4642a2e2b9291c2.jpg")!))
                })
            }
        }
    }
    //
    //    override func isContentValid() -> Bool {
    //        // Do validation of contentText and/or NSExtensionContext attachments here
    //        return true
    //    }
    //
    //    override func didSelectPost() {
    //        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    //
    //        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    //
    //        UserDefaults(suiteName: suiteName)?.set(self.shareURL, forKey: keyName)
    //        DispatchQueue.main.async {
    //            self.extensionContext?.open(URL(string:"iDownloader://")!, completionHandler: { val in
    //                print("Opened Status : \(val)")
    //            })
    //            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    //
    //        }
    //    }
    //
    //    override func configurationItems() -> [Any]! {
    //        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    //        return []
    //    }

}


//MARK: - Webview delegate setup
extension ShareViewController: WKNavigationDelegate{

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        debugPrint("HOST : \(navigationAction.request.url?.host ?? "NIL")")
        debugPrint("Requested URL : \(navigationAction.request.url?.absoluteString ?? "NIL")")
        if let host = navigationAction.request.url?.host {
            if host == "www.instagram.com" {
                decisionHandler(.allow)
                if navigationAction.request.url?.absoluteString.contains("https://www.instagram.com/accounts/onetap/") ?? false{
                    self.overlayview.isHidden = true
                    self.stopLoader(loader: self.loader)
                    print("LOG : Login successfully...")
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
        guard let activeLink = self.checkLink(self.shareURL?.absoluteString ?? "") else {
            self.stopLoader(loader: self.loader)
            print("LOG : Invalid Link")
            return
        }
        self.getMediaPost(with: activeLink)
        UserDefaults(suiteName: suiteName)?.set(nil, forKey: keyName)
    }
}

//MARK: - InstaSave
extension ShareViewController{

    func checkLink(_ link: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "^https://(www.)?instagram.com/.*/", options: .caseInsensitive)
        let matches = regex.matches(in: link, options: [], range: NSMakeRange(0, link.count))
        guard !matches.isEmpty else {
            self.stopLoader(loader: self.loader)
            print("LOG : Invalid Link")
            return nil
        }
        if let activeLink = link.components(separatedBy: "?").first {
            return activeLink
        } else {
            self.stopLoader(loader: self.loader)
            print("LOG : Invalid Link")
            return nil
        }
    }

    func getMediaPost(with link: String) {
        getJson(link) { json in
            guard let json = json else {
                self.stopLoader(loader: self.loader)
                print("LOG : data not found, please try again")
                return
            }
            self.parseJson(json)
        }
    }

    func getJson(_ link: String, completion: @escaping (Json?) -> ()) {
        let url = URL(string: "\(link)?__a=1&__d=dis")!

        web.configuration.websiteDataStore.httpCookieStore.getAllCookies({ cookies in
            var c = [HTTPCookie]()
            for cookie in cookies {
                //...
                print(cookie)
                c.append(cookie)
            }

//            HTTPCookie.cookies(withResponseHeaderFields: ["csrftoken":"PZnj00knZg6PADdAMTddg31UwSxlap1b", "sessionid":"49799874841%3A9giOLjRWeFFaqK%3A8%3AAYf2XlMzF_zSHMBF0qeW3tk0S5HvUg3MtLmPOX4_kA", "ds_user_id":"49799874841"], for: url)
//            let staticCookies = [HTTPCookie(properties: [HTTPCookiePropertyKey.init(rawValue: "sessionid"):"49799874841%3A9giOLjRWeFFaqK%3A8%3AAYf2XlMzF_zSHMBF0qeW3tk0S5HvUg3MtLmPOX4_kA"])!,
//                                 HTTPCookie(properties: [HTTPCookiePropertyKey.init(rawValue: "ds_user_id"):"49799874841"])!]
//            // First
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
                        print("LOG : \(error?.localizedDescription ?? "something went wrong, please try again")")
                    }else{
                        print("LOG : data not found, please try again")
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
           print("LOG : please try again or use another url")
            return
        }
        guard let item = items.first else{
            print("Items not found")
            self.stopLoader(loader: self.loader)
            print("LOG : please try again or use another url")
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
                            print("LOG : data not found, please try again")
                            return
                        }

                        SaveService.saveContent(type: images, MediaType.image.rawValue, url) { (url, error) in
                            if let error = error {
                                switch error {
                                case .accessDenied :
                                    self.stopLoader(loader: self.loader)
                                    self.alert(msg: "Please allow photos access from settings to save media in album")
                                case .unknown :
                                    self.stopLoader(loader: self.loader)
                                  print("LOG : Having some issue to save, please try again")
                                }
                            } else {
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Image Downloaded")
                                DispatchQueue.main.async {
                                    if let imgURL = url, let imgData = try? Data(contentsOf: imgURL){
                                        self.img_thumb.image = UIImage(data: imgData)
                                    }
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
                                    print("LOG : Content data not found")
                                    return
                                }

                                SaveService.saveContent(type: images, MediaType.image.rawValue, url) { url, error in
                                    if error != nil {
                                        switch error {
                                        case .accessDenied :
                                            self.stopLoader(loader: self.loader)
                                            self.alert(msg: "Please allow photos access from settings to save media in album")
                                        case .unknown :
                                            self.stopLoader(loader: self.loader)
                                            print("LOG : Having some issue to save, please try again")
                                        case .none:
                                            self.stopLoader(loader: self.loader)
                                            print("LOG : Content data not found, please try with another link")
                                        }
                                    } else {
                                        self.stopLoader(loader: self.loader)
//                                        self.alert(msg: "Image Downloaded")
                                        DispatchQueue.main.async {
                                            if let imgURL = url, let imgData = try? Data(contentsOf: imgURL){
                                                self.img_thumb.image = UIImage(data: imgData)

                                                let caption = item["caption"] as? NSDictionary
                                                let text = caption?["text"] as? String ?? "-"

                                                let user = caption?["user"] as? NSDictionary
                                                let username = user?["username"] as? String ?? "-"

                                                self.lbl_desc.text = text
                                                self.lbl_titile.text = username
                                            }
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
                print("LOG : Content data not found, please try with another link")
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
                        SaveService.saveContent(type: videos, MediaType.video.rawValue, url) { url, error in
                            if let error = error {
                                switch error {
                                case .accessDenied :
                                    self.stopLoader(loader: self.loader)
                                    self.alert(msg: "Please allow photos access from settings to save media in album")
                                case .unknown :
                                    self.stopLoader(loader: self.loader)
                                   print("LOG : Having some issue to save, please try again")
                                }
                            } else {
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Video Downloaded")

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
                                SaveService.saveContent(type: videos, MediaType.video.rawValue, url) { url, error in
                                    if let error = error {
                                        switch error {
                                        case .accessDenied :
                                            self.stopLoader(loader: self.loader)
                                            self.alert(msg: "Please allow photos access from settings to save media in album")
                                        case .unknown :
                                            self.stopLoader(loader: self.loader)
                                            print("LOG : Having some issue to save, please try again")
                                        }
                                    } else {
                                        self.stopLoader(loader: self.loader)
                                        self.alert(msg: "Video Downloaded")
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
               print("LOG : Content data not found, please try with another link")
            }
        case 8:
            print("CAROUSEL_MEDIA")
            if let carousel_media = item["carousel_media"] as? [Json]{
                self.carousel_media = carousel_media
                self.carousel_media_index = 0
                self.downloadCarousolMedia()

            }else{
                self.stopLoader(loader: self.loader)
                print("LOG : Content data not found, please try with another link")
            }
        default:
            print("LOG : unsupported media, please try with another link")
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

                    SaveService.saveContent(type: images, MediaType.image.rawValue, url) { url, error in
                        if let error = error {
                            switch error {
                            case .accessDenied :
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Please allow photos access from settings to save media in album")
                            case .unknown :
                                self.stopLoader(loader: self.loader)
                                print("LOG : Having some issue to save, please try again")
                            }
                        } else {
                            if self.carousel_media.count == self.carousel_media_index{
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Downloaded...")
                            }else{
                                self.downloadCarousolMedia()
                            }
                        }
                    }
                }else{
                    self.stopLoader(loader: self.loader)
                print("LOG : Content data not found, please try with another link")
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
                    SaveService.saveContent(type: videos, MediaType.video.rawValue, url) { url, error in
                        if let error = error {
                            switch error {
                            case .accessDenied :
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Please allow photos access from settings to save media in album")
                            case .unknown :
                                self.stopLoader(loader: self.loader)
                                print("LOG : Having some issue to save, please try again")
                            }
                        } else {
                            if self.carousel_media.count == self.carousel_media_index{
                                self.stopLoader(loader: self.loader)
                                self.alert(msg: "Downloaded...")
                            }else{
                                self.downloadCarousolMedia()
                            }
                        }
                    }
                }else{
                    self.stopLoader(loader: self.loader)
                    print("LOG : Content data not found, please try with another link")
                }
            default:
                print("LOG : unsupported media, please try with another link")
            }
        }
    }
}

