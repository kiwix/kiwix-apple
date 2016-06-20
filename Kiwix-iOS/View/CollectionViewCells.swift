//
//  CollectionViewCells.swift
//  Kiwix
//
//  Created by Chris Li on 6/19/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class LocalLangCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        layer.cornerRadius = 10.0
        layer.masksToBounds = true
        backgroundColor = UIColor.themeColor
    }
}

class BookCollectionCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        favIcon.layer.cornerRadius = 4.0
        favIcon.layer.masksToBounds = true
    }
}
