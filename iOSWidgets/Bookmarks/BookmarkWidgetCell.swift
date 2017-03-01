//
//  BookmarkWidgetCell.swift
//  Kiwix
//
//  Created by Chris Li on 7/20/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class BookmarkWidgetCell: UICollectionViewCell {
    override func awakeFromNib() {
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 4.0
        imageBackgroundView.layer.masksToBounds = true
        imageBackgroundView.layer.cornerRadius = 6.0
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageBackgroundView: UIView!
    @IBOutlet weak var label: UILabel!
}
