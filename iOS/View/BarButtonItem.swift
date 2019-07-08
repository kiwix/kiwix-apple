//
//  BarButtonItem.swift
//  iOS
//
//  Created by Chris Li on 1/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class BarButtonItem: UIBarButtonItem {
    
    private let gestureRecognizer = UILongPressGestureRecognizer()
    fileprivate weak var delegate: BarButtonItemDelegate? = nil
    
    var button: BarButton {
        get {return customView as! BarButton}
    }
    
    var isFocused: Bool = false
    
    convenience init(image: UIImage, inset: CGFloat, delegate: BarButtonItemDelegate?=nil) {
        self.init(customView: BarButton(inset: inset))
        self.delegate = delegate
        configure()
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    fileprivate func configure() {
        button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
        button.addGestureRecognizer(gestureRecognizer)
        gestureRecognizer.addTarget(self, action: #selector(buttonLongPressed(gestureRecognizer:)))
        
        if #available(iOS 11.0, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1.0).isActive = true
        } else {
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        }
    }
    
    @objc func buttonTapped(button: UIButton) {
        delegate?.buttonTapped(item: self, button: customView as! UIButton)
    }
    
    @objc func buttonLongPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else {return}
        delegate?.buttonLongPressed(item: self, button: customView as! UIButton)
    }
}

class BookmarkButtonItem: BarButtonItem {
    override var button: BookmarkBarButton {
        get {return customView as! BookmarkBarButton}
    }
    
    convenience init(delegate: BarButtonItemDelegate?=nil) {
        self.init(customView: BookmarkBarButton(inset: 8))
        self.delegate = delegate
        configure()
        button.setImage(#imageLiteral(resourceName: "Star").withRenderingMode(.alwaysTemplate), for: .normal)
        button.adjustsImageWhenHighlighted = false
    }
}

class BarButton: UIButton {
    private var boundsObserver: NSKeyValueObservation? = nil
    private(set) var inset: CGFloat = 0
    
    convenience init(inset: CGFloat) {
        self.init(frame: .zero)
        self.inset = inset
    }
    
    override var bounds: CGRect {
        didSet {
            let inset: CGFloat = {
                if #available(iOS 11.0, *) {
                    if bounds.height < 44 {
                        return self.inset * 0.6
                    } else {
                        return self.inset
                    }
                } else {
                    return self.inset
                }
            }()
            imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        }
    }
    
//    private let selectionLayer = CALayer()
//
//    override func draw(_ rect: CGRect) {
//        selectionLayer.frame = rect.insetBy(dx: 6, dy: 6)
//        selectionLayer.backgroundColor = #colorLiteral(red: 0, green: 0.3529411765, blue: 1, alpha: 1) .cgColor
//        if let layers = layer.sublayers, !layers.contains(selectionLayer) {
//            selectionLayer.cornerRadius = 4.0
//            self.layer.insertSublayer(selectionLayer, at: 0)
//        }
//    }
}

class BookmarkBarButton: BarButton {
    override var isHighlighted: Bool {
        didSet {
            tintColor = isBookmarked ? #colorLiteral(red: 1, green: 0.7960784314, blue: 0.2196078431, alpha: 1) : nil
        }
    }
    
    var isBookmarked: Bool = false {
        didSet {
            if isBookmarked {
                setImage(#imageLiteral(resourceName: "StarFilled").withRenderingMode(.alwaysTemplate), for: .normal)
                tintColor = #colorLiteral(red: 1, green: 0.7960784314, blue: 0.2196078431, alpha: 1)
            } else {
                setImage(#imageLiteral(resourceName: "Star").withRenderingMode(.alwaysTemplate), for: .normal)
                tintColor = nil
            }
        }
    }
}

protocol BarButtonItemDelegate: class {
    func buttonTapped(item: BarButtonItem, button: UIButton)
    func buttonLongPressed(item: BarButtonItem, button: UIButton)
}
