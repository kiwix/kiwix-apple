//
//  ShadowView.swift
//  Kiwix
//
//  Created by Chris Li on 6/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class DropShadowView: UIView {
    override func drawRect(rect: CGRect) {
        layer.masksToBounds = false
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowRadius = 2.0
        layer.shadowOpacity = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).CGPath
    }
}

class SearchHRegularDropShadowView: UIView {
    override func awakeFromNib() {
        layer.masksToBounds = false
        layer.cornerRadius = 10.0
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowRadius = 50.0
        layer.shadowOpacity = 0.1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).CGPath
    }
}

class SearchRoundedCornerView: UIView {
    override func awakeFromNib() {
        layer.masksToBounds = true
        layer.cornerRadius = 10.0
    }
}