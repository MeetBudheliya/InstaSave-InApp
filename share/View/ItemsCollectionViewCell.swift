//
//  ItemsCollectionViewCell.swift
//  share
//
//  Created by Meet's MAC on 20/05/22.
//

import UIKit

class ItemsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var contentImage: UIImageView!
    @IBOutlet weak var removeBTN: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    
    }

    // image and container view layout
    func viewLayoutSetup(){
        self.containerView.layer.shadowColor = UIColor.lightGray.cgColor
        self.containerView.layer.shadowOpacity = 1
        self.containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.containerView.layer.shadowRadius = 3
        self.containerView.layer.cornerRadius = 8
        self.contentImage.layer.cornerRadius = 8
    }

}
