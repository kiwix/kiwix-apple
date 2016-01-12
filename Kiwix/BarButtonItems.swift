//
//  UIBarButtonItemExtention.swift
//  Grid
//
//  Created by Chris on 12/9/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class MessageBarButtonItem: UIBarButtonItem {
    var text: String? {
        get {return label.text}
        set {label.text = newValue}
    }
    
    let label: UILabel = {
        let label = UILabel(frame: CGRectMake(0, 0, 220, 40))
        label.textAlignment = .Center
        label.numberOfLines = 1
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
        return label
    }()
    
    override init() {
        super.init()
        self.customView = label
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(labelText text: String?) {
        self.init()
        self.customView = label
        self.label.text = text
    }
    
    func setText(text: String?, animated: Bool) {
        if animated {
            let animation = CATransition()
            animation.duration = 0.2
            animation.type = kCATransitionFade
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            label.layer.addAnimation(animation, forKey: "changeTextTransition")
            label.text = ""
            label.text = text
        } else {
            label.text = text
        }
    }
}

// Long Press & Tap BarButtonItem
class LPTBarButtonItem: UIBarButtonItem {
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(image: UIImage?, highlightedImage: UIImage?, target: AnyObject?, longPressAction: Selector, tapAction: Selector) {
        let customImageView = LargeHitZoneImageView(image: image?.imageWithRenderingMode(.AlwaysTemplate),
                                                    highlightedImage: highlightedImage?.imageWithRenderingMode(.AlwaysTemplate))
        customImageView.contentMode = UIViewContentMode.ScaleAspectFit
        customImageView.frame = CGRectMake(0, 0, 26, 26)
        customImageView.tintColor = UIColor.grayColor()
        let containerView = UIView(frame: CGRectMake(0, 0, 52, 30))
        customImageView.center = containerView.center
        containerView.addSubview(customImageView)
        self.init(customView: containerView)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target
            : target, action: longPressAction)
        let tapGestureRecognizer = UITapGestureRecognizer(target: target, action: tapAction)
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    convenience init(imageName: String, highlightedImageName: String, delegate: LPTBarButtonItemDelegate) {
        let customImageView = LargeHitZoneImageView(image: UIImage(named: imageName)?.imageWithRenderingMode(.AlwaysTemplate),
            highlightedImage: UIImage(named: highlightedImageName)?.imageWithRenderingMode(.AlwaysTemplate))
        customImageView.contentMode = UIViewContentMode.ScaleAspectFit
        customImageView.frame = CGRectMake(0, 0, 26, 26)
        //customImageView.tintColor = UIColor.grayColor()
        let containerView = UIView(frame: CGRectMake(0, 0, 52, 30))
        customImageView.center = containerView.center
        containerView.addSubview(customImageView)
        self.init(customView: containerView)

        self.delegate = delegate
        self.customImageView = customImageView
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    weak var delegate: LPTBarButtonItemDelegate?
    var customImageView: LargeHitZoneImageView?
    
    func handleTapGesture(gestureRecognizer: UIGestureRecognizer) {
        delegate?.barButtonTapped(self, gestureRecognizer: gestureRecognizer)
    }
    
    func handleLongPressGesture(gestureRecognizer: UIGestureRecognizer) {
        guard gestureRecognizer.state == .Began else {return}
        delegate?.barButtonLongPressedStart(self, gestureRecognizer: gestureRecognizer)
    }
}

protocol LPTBarButtonItemDelegate: class {
    func barButtonTapped(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer)
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer)
}

// MARK: - Helper Class

class LargeHitZoneImageView: UIImageView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let frame = CGRectInset(self.bounds, -9, -9)
        return CGRectContainsPoint(frame, point) ? self : nil
    }
}