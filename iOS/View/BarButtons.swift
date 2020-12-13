//
//  BarButtons.swift
//  Kiwix
//
//  Created by Chris Li on 8/27/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit

private extension UIControl.State {
    static let bookmarked = UIControl.State(rawValue: 1 << 16)
}

class BarButtonGroup: UIStackView {
    convenience init(buttons: [UIButton], spacing: CGFloat? = nil) {
        self.init(arrangedSubviews: buttons)
        distribution = .equalCentering
        if let spacing = spacing {
            self.spacing = spacing
        }
    }
}

class BarButton: UIButton {
    convenience init(imageName: String) {
        self.init(type: .system)
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(scale: .large)
            setImage(UIImage(systemName: imageName, withConfiguration: configuration) ?? UIImage(named: imageName), for: .normal)
        } else {
            setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 44)
    }
}

class BookmarkButton: BarButton {
    var isBookmarked: Bool = false { didSet { setNeedsLayout() } }
    override var state: UIControl.State{ get { isBookmarked ? [.bookmarked, super.state] : super.state } }
    
    convenience init(imageName: String, bookmarkedImageName: String) {
        if #available(iOS 13.0, *) {
            self.init(imageName: imageName)
            let configuration = UIImage.SymbolConfiguration(scale: .large)
            let bookmarkedImage = UIImage(systemName: bookmarkedImageName, withConfiguration: configuration)?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            setImage(bookmarkedImage, for: .bookmarked)
            setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
        } else {
            self.init(type: .system)
            setImage(UIImage(named: imageName), for: .normal)
            let bookmarkedImage = UIImage(named: bookmarkedImageName)
            setImage(bookmarkedImage, for: .bookmarked)
            setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
        }
    }
}
