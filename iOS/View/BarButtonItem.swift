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
    convenience init(image: UIImage, highlightedImage: UIImage?=nil, inset: CGFloat, target: Any?, action: Selector?) {
        let button = UIButton()
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(highlightedImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        
        self.init(customView: button)
        
        if #available(iOS 11.0, *) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1.0).isActive = true
        } else {
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        }
        
        self.target = target as AnyObject
        self.action = action
        
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
    }
}
