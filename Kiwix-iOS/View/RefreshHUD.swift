//
//  RefreshHUD.swift
//  Grid
//
//  Created by Chris on 10/16/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class RefreshHUD: UIVisualEffectView {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    
    convenience init(blurEffectStyle: UIBlurEffectStyle) {
        let effect = UIBlurEffect(style: blurEffectStyle)
        self.init(effect: effect)
    }
    
    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        
        self.layer.cornerRadius = 20.0
        self.layer.borderColor = UIColor.blackColor().colorWithAlphaComponent(0.4).CGColor
        self.layer.borderWidth = 1.0
        self.backgroundColor = UIColor.clearColor()
        self.layer.masksToBounds = true
        
        activityIndicator.color = UIColor.whiteColor()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityIndicator)
        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: activityIndicator, attribute: .CenterX, multiplier: 1, constant: 0)
        self.addConstraint(xCenterConstraint)
        
        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .CenterY, relatedBy: .Equal, toItem: activityIndicator, attribute: .CenterY, multiplier: 1, constant: 0)
        self.addConstraint(yCenterConstraint)
        
        activityIndicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        activityIndicator.stopAnimating()
    }
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
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