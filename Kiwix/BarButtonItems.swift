//
//  BarButtonItems.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SpinningBarButtonItem: UIBarButtonItem {
    var isSpinning = false
    var imageView = UIImageView()
    var button = LargeTouchDetectionButton(type: .Custom)
    
    convenience init(withImage customImage: UIImage) {
        self.init()
        imageView.image = customImage.imageWithRenderingMode(.AlwaysTemplate)
        imageView.autoresizingMask = UIViewAutoresizing.None
        imageView.contentMode = UIViewContentMode.Center
        
        button.frame = CGRectMake(0, 0, 40, 40)
        button.addSubview(imageView)
        button.tintColor = nil
        imageView.center = button.center
        
        let view = self.customView
        self.customView?.addSubview(button)
    }
    
    
    func startSpinning() {
        if self.imageView.isAnimating() {
            return
        }
        isSpinning = true
        button.enabled = false
        rotateSpinningView()
    }
    
    func stopSpinning() {
        isSpinning = false
        button.enabled = true
    }
    
    func rotateSpinningView() {
        UIView.animateWithDuration(0.4, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, CGFloat(M_PI_2))
            }) { (finished) -> Void in
                if finished && self.isSpinning {
                    self.rotateSpinningView()
                }
        }
    }
}

class LargeTouchDetectionButton: UIButton {
    override func alignmentRectInsets() -> UIEdgeInsets {
        return UIEdgeInsetsMake(0.0, 9.0, 0.0, 9.0)
    }
}