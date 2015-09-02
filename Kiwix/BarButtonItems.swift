//
//  BarButtonItems.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class BarButtonItemCustomImageView: UIImageView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let frame = CGRectInset(self.bounds, -9, -9)
        return CGRectContainsPoint(frame, point) ? self : nil
    }
}

class SpinningBarButtonItem: UIBarButtonItem {
    var isSpinning = false
    var imageView = UIImageView()
    var button = LargeTouchDetectionButton(type: .Custom)
    
//    init(withImage customImage: UIImage) {
//        
//        imageView.image = customImage.imageWithRenderingMode(.AlwaysTemplate)
//        imageView.autoresizingMask = UIViewAutoresizing.None
//        imageView.contentMode = UIViewContentMode.Center
//        
//        button.frame = CGRectMake(0, 0, 40, 40)
//        button.addSubview(imageView)
//        button.tintColor = nil
//        imageView.center = button.center
//        
//        let view = self.customView
//        self.customView?.addSubview(button)
//        let view = UIView()
//        super.init(customView: view)
//    }

    
    
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

class MessageBarButtonItem: UIBarButtonItem {
    let label: UILabel = {
        let label = UILabel(frame: CGRectMake(0, 0, 180, 40))
        label.textAlignment = .Center
        label.numberOfLines = 1
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        return label
    }()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(withLabelText text: String) {
        self.init(customView: UIView())
        self.customView = label
        self.label.text = text
    }
}

class LongPressAndTapBarButtonItem: UIBarButtonItem {
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(image: UIImage?, highlightedImage: UIImage?, target: AnyObject?, longPressAction: Selector, tapAction: Selector) {
        let customImageView = BarButtonItemCustomImageView(image: image?.imageWithRenderingMode(.AlwaysTemplate), highlightedImage: highlightedImage?.imageWithRenderingMode(.AlwaysTemplate))
        customImageView.contentMode = UIViewContentMode.ScaleAspectFit
        customImageView.frame = CGRectMake(0, 0, 22, 22)
        let containerView = UIView(frame: CGRectMake(0, 0, 32, 30))
        customImageView.center = containerView.center
        containerView.addSubview(customImageView)
        self.init(customView: containerView)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: target, action: longPressAction)
        let tapGestureRecognizer = UITapGestureRecognizer(target: target, action: tapAction)
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
}