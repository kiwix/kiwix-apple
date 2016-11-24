//
//  ShadowView.swift
//  Kiwix
//
//  Created by Chris Li on 6/14/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class DropShadowView: UIView {
    var bottomBorder: CALayer?
    override func draw(_ rect: CGRect) {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            layer.shadowRadius = 0.0
            layer.shadowOpacity = 0.0
            layer.backgroundColor = UIColor.white.cgColor
            
            let border: CALayer = {
                if let border = bottomBorder {
                    return border
                } else {
                    let border = CALayer()
                    bottomBorder = border
                    border.backgroundColor = UIColor.lightGray.withAlphaComponent(0.75).cgColor
                    return border
                }
            }()
            border.frame = CGRect(x: 0, y: rect.height - 0.5, width: rect.width, height: 0.5)
            layer.addSublayer(border)
        case .compact:
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 0.5
            layer.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0).cgColor
            if let border = bottomBorder {border.removeFromSuperlayer()}
        default:
            break
        }
    }
    
    override func awakeFromNib() {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        setNeedsDisplay()
    }
}

class SearchHRegularDropShadowView: UIView {
    override func awakeFromNib() {
        layer.masksToBounds = false
        layer.cornerRadius = 10.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 50.0
        layer.shadowOpacity = 0.2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }
}

class SearchRoundedCornerView: UIView {
    
    override func awakeFromNib() {
        layer.masksToBounds = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard traitCollection != previousTraitCollection else {return}
        switch traitCollection.horizontalSizeClass {
        case .regular:
            layer.cornerRadius = 10.0
        case .compact:
            layer.cornerRadius = 0.0
        default:
            break
        }
    }
    
}

class LargeHitZoneImageView: UIImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = self.bounds.insetBy(dx: -9, dy: -9)
        return frame.contains(point) ? self : nil
    }
}
