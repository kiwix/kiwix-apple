//
//  RefreshHUD.swift
//  Grid
//
//  Created by Chris on 10/16/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class RefreshHUD: UIVisualEffectView {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    convenience init(blurEffectStyle: UIBlurEffectStyle) {
        let effect = UIBlurEffect(style: blurEffectStyle)
        self.init(effect: effect)
    }
    
    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        
        self.layer.cornerRadius = 20.0
        self.layer.borderColor = UIColor.black.withAlphaComponent(0.4).cgColor
        self.layer.borderWidth = 1.0
        self.backgroundColor = UIColor.clear
        self.layer.masksToBounds = true
        
        activityIndicator.color = UIColor.white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityIndicator)
        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
        self.addConstraint(xCenterConstraint)
        
        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraint(yCenterConstraint)
        
        activityIndicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        activityIndicator.stopAnimating()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if let _ = newSuperview {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
//    override func drawRect(rect: CGRect) {
//
//    }
}
