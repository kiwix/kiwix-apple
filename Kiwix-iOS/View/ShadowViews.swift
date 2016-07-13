//
//  ShadowView.swift
//  Kiwix
//
//  Created by Chris Li on 6/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class DropShadowView: UIView {
    var bottomBorder: CALayer?
    override func drawRect(rect: CGRect) {
        switch traitCollection.horizontalSizeClass {
        case .Regular:
            layer.shadowRadius = 0.0
            layer.shadowOpacity = 0.0
            layer.backgroundColor = UIColor.whiteColor().CGColor
            
            let border: CALayer = {
                if let border = bottomBorder {
                    return border
                } else {
                    let border = CALayer()
                    bottomBorder = border
                    border.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.75).CGColor
                    border.frame = CGRectMake(0, rect.height - 0.5, rect.width, 0.5)
                    return border
                }
            }()
            layer.addSublayer(border)
        case .Compact:
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 0.5
            layer.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0).CGColor
            if let border = bottomBorder {border.removeFromSuperlayer()}
        default:
            break
        }
    }
    
    override func awakeFromNib() {
        layer.masksToBounds = false
        layer.shadowOffset = CGSizeMake(0, 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).CGPath
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        guard previousTraitCollection != traitCollection else {return}
        setNeedsDisplay()
    }
}

class SearchHRegularDropShadowView: UIView {
    override func awakeFromNib() {
        layer.masksToBounds = false
        layer.cornerRadius = 10.0
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowRadius = 50.0
        layer.shadowOpacity = 0.2
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