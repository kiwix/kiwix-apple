//
//  UIBarButtonItemExtention.swift
//  Grid
//
//  Created by Chris on 12/9/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class LPTBarButtonItem: UIBarButtonItem {
    
    convenience init(imageName: String,
                     highlightedImageName: String? = nil,
                     scale: CGFloat = 1.0,
                     grayed: Bool = true,
                     delegate: LPTBarButtonItemDelegate? = nil,
                     accessibilityLabel: String? = nil,
                     accessibilityIdentifier: String? = nil) {
        var image = UIImage(named: imageName)
        var highlightedImage: UIImage? = {
            guard let name = highlightedImageName else {return nil}
            return UIImage(named: name)
        }()
        
        if grayed {
            image = image?.withRenderingMode(.alwaysTemplate)
            highlightedImage = highlightedImage?.withRenderingMode(.alwaysTemplate)
        }
        
        let imageView = UIImageView(image: image, highlightedImage: highlightedImage)
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        if grayed {imageView.tintColor = UIColor.gray}
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30)) // on ipad may be 52, 44 is value on iP6s+, to be investigated
        imageView.center = containerView.center
        containerView.addSubview(imageView)
        self.init(customView: containerView)

        self.delegate = delegate
        self.imageView = imageView
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gesture:)))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(gesture:)))
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
        
        self.isAccessibilityElement = true
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    // MARK: - Overrides
    
    override var tintColor: UIColor? {
        didSet {
            imageView?.tintColor = tintColor
        }
    }
    
    var isHighlighted: Bool = false {
        didSet {
            imageView?.isHighlighted = isHighlighted
        }
    }
    
    // MARK: - properties
    
    weak var delegate: LPTBarButtonItemDelegate?
    private(set) var imageView: UIImageView?
    private(set) var isRotating = false
    
    // MARK: - handle gesture
    
    func handleTapGesture(gesture: UITapGestureRecognizer) {
        delegate?.barButtonTapped(sender: self, gesture: gesture)
    }
    
    func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {return}
        delegate?.barButtonLongPressedStart(sender: self, gesture: gesture)
    }
}

protocol LPTBarButtonItemDelegate: class {
    func barButtonTapped(sender: LPTBarButtonItem, gesture: UITapGestureRecognizer)
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gesture: UILongPressGestureRecognizer)
}

extension LPTBarButtonItemDelegate {
    func barButtonTapped(sender: LPTBarButtonItem, gesture: UITapGestureRecognizer) {return}
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gesture: UILongPressGestureRecognizer) {return}
}

class MessageBarButtonItem: UIBarButtonItem {
    var text: String? {
        get {return label.text}
        set {label.text = newValue}
    }
    
    let label: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 220, height: 40))
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)
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
    
    func setText(_ text: String?, animated: Bool) {
        if animated {
            let animation = CATransition()
            animation.duration = 0.2
            animation.type = kCATransitionFade
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            label.layer.add(animation, forKey: "changeTextTransition")
            label.text = ""
            label.text = text
        } else {
            label.text = text
        }
    }
}

class LibraryMoreButton: UIButton {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }
        let rect = bounds.insetBy(dx: -16, dy: 0)
        return rect.contains(point) ? self : nil
    }
}
