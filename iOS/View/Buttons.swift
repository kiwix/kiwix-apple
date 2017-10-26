//
//  Buttons.swift
//  iOS
//
//  Created by Chris Li on 10/25/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {
    init() {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        setTitleColor(.white, for: .normal)
        setTitleColor(.lightText, for: .highlighted)
        backgroundColor = #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1)
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? #colorLiteral(red: 0, green: 0.3529411765, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1)
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? #colorLiteral(red: 0, green: 0.3529411765, blue: 1, alpha: 1) : #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width, height: size.height + 18)
        }
    }
}
