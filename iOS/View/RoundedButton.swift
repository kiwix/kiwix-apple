//
//  Buttons.swift
//  iOS
//
//  Created by Chris Li on 10/25/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {
    private let normalColor = #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1)
    private let highlightedColor = #colorLiteral(red: 0, green: 0.3529411765, blue: 1, alpha: 1)
    private let disabledColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    
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
        backgroundColor = normalColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }
    
    private func configureBackgroundColor() {
        if isEnabled {
            backgroundColor = isHighlighted ? #colorLiteral(red: 0, green: 0.3529411765, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0.431372549, blue: 1, alpha: 1)
        } else {
            backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        }
    }
    
    override var isHighlighted: Bool {
        didSet { configureBackgroundColor() }
    }
    
    override var isEnabled: Bool {
        didSet { configureBackgroundColor() }
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            let size = super.intrinsicContentSize
            if #available(iOS 11.0, *) {
                return CGSize(width: CGFloat.greatestFiniteMagnitude, height: size.height + 18)
            } else {
                return CGSize(width: 1000, height: size.height + 18)
            }
        }
    }
}
