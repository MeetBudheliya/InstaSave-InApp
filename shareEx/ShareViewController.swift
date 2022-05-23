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

let suiteName = "group.com.meet.InstaSave.Extension"
let keyName = "shareURL"

class ShareViewController: SLComposeServiceViewController {

var shareURL = URL(string: "https://www.google.co.in/")
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
           })
         }
       }
     }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.

        UserDefaults(suiteName: suiteName)?.set(self.shareURL, forKey: keyName)
        DispatchQueue.main.async {
            self.extensionContext?.open(URL(string:"iDownloader://")!, completionHandler: { val in
                print("Opened Status : \(val)")
            })
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)

        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
