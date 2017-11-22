//
//  MiscViews.swift
//  Kiwix
//
//  Created by Chris Li on 11/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class DimView: UIView {
    var isDimmed: Bool = false {
        didSet {
            backgroundColor = isDimmed ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }
}

class TabToolbarButton: UIBarButtonItem {
    private var button: UIButton {
        get {return customView as! UIButton}
    }
    convenience init(image: UIImage, insets: UIEdgeInsets = .zero) {
        self.init(customView: UIButton())
        button.imageEdgeInsets = insets
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.layer.cornerRadius = 4
        button.imageView?.clipsToBounds = true
    }
    
    var isHighlighted: Bool = false {
        didSet {
            button.backgroundColor = isHighlighted ? UIColor.lightGray.withAlphaComponent(0.5) : UIColor.clear
        }
    }

    var isSelected: Bool = false {
        didSet {
            button.imageView?.tintColor = isSelected ? UIColor.white : nil
            button.imageView?.backgroundColor = isSelected ? #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1) : UIColor.clear
        }
    }
}
