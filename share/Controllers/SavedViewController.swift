//
//  SavedViewController.swift
//  share
//
//  Created by Meet's MAC on 19/05/22.
//

import UIKit
import QuickLook

class SavedViewController: UIViewController {

    @IBOutlet weak var noDataImage: UIImageView!
    @IBOutlet weak var collection: UICollectionView!

    var videosList = [URL]()
    var imagesList = [URL]()
    var openFileUrl = URL(string: "https://www.google.com/")!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionSetup()
        self.GetData()
    }

    func GetData(){
        self.videosList = SaveService.shared.load(type: videos) ?? []
        self.imagesList = SaveService.shared.load(type: images) ?? []

        if self.videosList.count == 0, self.imagesList.count == 0{
            self.noDataImage.isHidden = false
        }else{
            self.noDataImage.isHidden = true
        }
        self.collection.reloadData()
    }

    @IBAction func clearAllButtonClick(_ sender: Any) {
        let fileManager = FileManager.default
        let myDocuments = [fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(videos), fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(images)]

        for folderPath in myDocuments{
            do {
                try fileManager.removeItem(at: folderPath)
            } catch {
                print("Unable to delete, please try again later")
            }
        }
        self.GetData()
    }

    @objc func clearVideos(){
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(videos)
        do {
            try fileManager.removeItem(at: myDocuments)
        } catch {
            self.alert(msg: "Unable to delete video, please try again later")
        }
        self.GetData()
    }

    @objc func clearImages(){
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(images)
        do {
            try fileManager.removeItem(at: myDocuments)
        } catch {
            self.alert(msg: "Unable to delete image, please try again later")
        }
        self.GetData()
    }

    @objc func removeItem(sender: UIButton){
        let sec = sender.superview?.tag ?? -1
        let ind = sender.tag
        let fileManager = FileManager.default
        if sec == 0{
            do {
                try fileManager.removeItem(at: videosList[ind])
                self.GetData()
            } catch {
                self.alert(msg: "Unable to delete video, please try again later")
            }
        }else if sec == 1{
            do {
                try fileManager.removeItem(at: imagesList[ind])
                self.GetData()
            } catch {
                self.alert(msg: "Unable to delete image, please try again later")
            }
        }else{
            print("else")
        }
    }
}

//MARK: - Collection view setup
extension SavedViewController: UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{


    func collectionSetup(){
        collection.delegate = self
        collection.dataSource = self
        collection.register(UINib(nibName: "ItemsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ItemsCollectionViewCell")
    }

    // section count
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    // set number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0{
            return videosList.count
        }else{
            return imagesList.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemsCollectionViewCell", for: indexPath) as! ItemsCollectionViewCell

        if indexPath.section == 0{
            cell.contentImage.image = makeThumbFromVideo(videosList[indexPath.row])
        }else{
            cell.contentImage.image = makeThumbFromImage(imagesList[indexPath.row])
        }

        cell.viewLayoutSetup()
        cell.removeBTN.superview?.tag = indexPath.section
        cell.removeBTN.tag = indexPath.row
        cell.removeBTN.addTarget(self, action: #selector(removeItem), for: .touchUpInside)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
             let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeader
            if indexPath.section == 0{
                if videosList.count == 0{
                    sectionHeader.isHidden = true
                }else{
                    sectionHeader.isHidden = false
                    sectionHeader.sectionHeader.text = "Saved Videos"
                    sectionHeader.clearSectionBTN.setTitle("Clear Videos", for: .normal)
                    sectionHeader.clearSectionBTN.addTarget(self, action: #selector(self.clearVideos), for: .touchUpInside)
                }
            }else{
                if imagesList.count == 0{
                    sectionHeader.isHidden = true
                }else{
                    sectionHeader.isHidden = false
                    sectionHeader.sectionHeader.text = "Saved Images"
                    sectionHeader.clearSectionBTN.setTitle("Clear Images", for: .normal)
                    sectionHeader.clearSectionBTN.addTarget(self, action: #selector(self.clearImages), for: .touchUpInside)
                }
            }
             return sectionHeader
        } else { //No footer in this case but can add option for that
             return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let quickLookController = QLPreviewController()
        if indexPath.section == 0{
            openFileUrl = videosList[indexPath.row]
        }else{
            openFileUrl = imagesList[indexPath.row]
        }
        quickLookController.dataSource = self
        quickLookController.currentPreviewItemIndex = 0
        self.present(quickLookController, animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 30)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 4, height: collectionView.frame.width / 4)
    }
}

//MARK: - QLPreviewController
extension SavedViewController: QLPreviewControllerDataSource{
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return openFileUrl as QLPreviewItem
    }
}

class SectionHeader: UICollectionReusableView {

    @IBOutlet weak var sectionHeader: UILabel!
    @IBOutlet weak var clearSectionBTN: UIButton!

    override init(frame: CGRect) {
         super.init(frame: frame)

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("init(coder:) has not been implemented")
    }
}
