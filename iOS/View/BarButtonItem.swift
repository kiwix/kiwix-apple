//
//  BarButtonItem.swift
//  iOS
//
//  Created by Chris Li on 1/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class BarButtonItem: UIBarButtonItem {
    private var buttonBoundsObserver: NSKeyValueObservation? = nil
    private weak var delegate: BarButtonItemDelegate? = nil
    
    var isGrayed: Bool = true {
        didSet {
            customView?.tintColor = isGrayed ? .gray : nil
        }
    }
    
    var isFocused: Bool = false
    
//    var isHighlighted: Bool = false {
//        didSet {
//            customView?.tintColor = isHighlighted ? .white : (isGrayed ? .gray : nil)
//            (customView as? UIButton)?.imageView?.backgroundColor = isHighlighted ? #colorLiteral(red: 0, green: 0.3529411765, blue: 1, alpha: 1) : nil
//        }
//    }
    
    convenience init(image: UIImage, highlightedImage: UIImage?=nil, inset: CGFloat, delegate: BarButtonItemDelegate?=nil) {
        let button = UIButton()
        button.tintColor = .gray
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(highlightedImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        
        self.init(customView: button)
        self.delegate = delegate
        
        if #available(iOS 11.0, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1.0).isActive = true
        } else {
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        }
        
        buttonBoundsObserver = button.observe(\.bounds, options: [.initial, .new]) { (button, change) in
            let inset: CGFloat = {
                if let height = change.newValue?.height, height < 44 {
                    return inset * 0.6
                } else {
                    return inset
                }
            }()
            button.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        }
        
        button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(button: UIButton) {
        delegate?.buttonTapped(item: self, button: customView as! UIButton)
    }
}

//class BarButton: UIButton {
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
//}

protocol BarButtonItemDelegate: class {
    func buttonTapped(item: BarButtonItem, button: UIButton)
}
