//
//  ToolbarController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class Buttons {
    
    private(set) lazy var back: UIBarButtonItem = LPTBarButtonItem(imageName: "LeftArrow", scale: 0.8)
    private(set) lazy var forward: UIBarButtonItem = LPTBarButtonItem(imageName: "RightArrow", scale: 0.8)
    private(set) lazy var toc: UIBarButtonItem = LPTBarButtonItem(imageName: "TableOfContent", scale: 0.8)
    private(set) lazy var bookmark: UIBarButtonItem = LPTBarButtonItem(imageName: "Bookmark", scale: 0.9)
    private(set) lazy var library: UIBarButtonItem = LPTBarButtonItem(imageName: "Library")
    private(set) lazy var setting: UIBarButtonItem = LPTBarButtonItem(imageName: "Setting")
    
    private(set) lazy var cancel: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapped(button:)))
    
    let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    var delegate: ButtonDelegates?
    
    var toolbar: [UIBarButtonItem] {return [back, space, forward, space, toc, space, bookmark, space, library, space, setting]}
    var navLeft: [UIBarButtonItem] {return [back, forward, toc]}
    var navRight: [UIBarButtonItem] {return [setting, library, bookmark]}
    
    
    @objc func tapped(button: UIBarButtonItem) {
        switch button {
        case back:
            delegate?.didTapBackButton()
        case forward:
            delegate?.didTapForwardButton()
        case bookmark:
            delegate?.didTapBookmarkButton()
        case library:
            delegate?.didTapLibraryButton()
        case cancel:
            delegate?.didTapCancelButton()
        default:
            return
        }
    }
    
    @objc func pressed(recognizer: UILongPressGestureRecognizer) {
        guard let view = recognizer.view, recognizer.state == .began else {return}
        switch view.tag {
        case 0:
            delegate?.didLongPressBackButton()
        case 1:
            delegate?.didLongPressForwardButton()
        case 3:
            delegate?.didLongPressBookmarkButton()
        default:
            return
        }
    }
}

protocol ButtonDelegates {
    func didTapBackButton()
    func didTapForwardButton()
    func didTapBookmarkButton()
    func didTapLibraryButton()
    func didTapCancelButton()
    
    func didLongPressBackButton()
    func didLongPressForwardButton()
    func didLongPressBookmarkButton()
}

class BarButton: UIBarButtonItem {
    private(set) var type = BarButtonType.blank
    convenience init(type: BarButtonType) {
        let imageView = UIImageView(image: UIImage(named: "Bookmark"))
        imageView.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        self.init(customView: imageView)
//        self.init(image: nil, style: .plain, target: nil, action: nil)
        self.type = type
    }
}

enum BarButtonType {
    case back, forward
    case tableOfContent, bookmark, library, setting
    case blank
}
