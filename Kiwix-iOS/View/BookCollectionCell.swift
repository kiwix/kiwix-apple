
//
//  BookCollectionCell.swift
//  Kiwix
//
//  Created by Chris Li on 1/31/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

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
