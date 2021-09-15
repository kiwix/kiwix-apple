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
        let image = UIImage(
            systemName: imageName, withConfiguration: UIImage.SymbolConfiguration(scale: .large)
        ) ?? UIImage(named: imageName)
        setImage(image, for: .normal)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 44)
    }
}

class BookmarkButton: BarButton {
    var isBookmarked: Bool = false { didSet { setNeedsLayout() } }
    override var state: UIControl.State{ get { isBookmarked ? [.bookmarked, super.state] : super.state } }
    
    convenience init(imageName: String, bookmarkedImageName: String) {
        self.init(imageName: imageName)
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        let bookmarkedImage = UIImage(systemName: bookmarkedImageName, withConfiguration: configuration)?
            .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        setImage(bookmarkedImage, for: .bookmarked)
        setImage(bookmarkedImage, for: [.bookmarked, .highlighted])
    }
}
