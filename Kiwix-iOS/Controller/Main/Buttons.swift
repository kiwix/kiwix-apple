//
//  ToolbarController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class Buttons: LPTBarButtonItemDelegate {
    
    private(set) lazy var back: LPTBarButtonItem = LPTBarButtonItem(imageName: "LeftArrow", scale: 0.8, delegate: self,
                                                                    accessibilityLabel: "Go back", accessibilityIdentifier: "GoBack")
    private(set) lazy var forward: LPTBarButtonItem = LPTBarButtonItem(imageName: "RightArrow", scale: 0.8, delegate: self,
                                                                       accessibilityLabel: "Go forward", accessibilityIdentifier: "GoForward")
    private(set) lazy var toc: LPTBarButtonItem = LPTBarButtonItem(imageName: "TableOfContent", scale: 0.8, delegate: self,
                                                                   accessibilityLabel: "Table of content", accessibilityIdentifier: "TableOfContent")
    private(set) lazy var bookmark: LPTBarButtonItem = LPTBarButtonItem(imageName: "Bookmark", highlightedImageName: "BookmarkHighlighted",
                                                                        scale: 0.9, grayed: false, delegate: self,
                                                                        accessibilityLabel: "Bookmark", accessibilityIdentifier: "Bookmark")
    private(set) lazy var library: LPTBarButtonItem = LPTBarButtonItem(imageName: "Library", delegate: self,
                                                                       accessibilityLabel: "Library", accessibilityIdentifier: "Library")
    private(set) lazy var setting: LPTBarButtonItem = LPTBarButtonItem(imageName: "Setting", delegate: self,
                                                                       accessibilityLabel: "Setting", accessibilityIdentifier: "Setting")
    
    private(set) lazy var cancel: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapped(button:)))
    
    let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    var delegate: ButtonDelegates?
    
    var toolbar: [UIBarButtonItem] {return [back, space, forward, space, toc, space, bookmark, space, library, space, setting]}
    var navLeft: [UIBarButtonItem] {return [back, forward, toc]}
    var navRight: [UIBarButtonItem] {return [setting, library, bookmark]}
    
    func barButtonTapped(sender: LPTBarButtonItem, gesture: UITapGestureRecognizer) {
        switch sender {
        case back:
            delegate?.didTapBackButton()
        case forward:
            delegate?.didTapForwardButton()
        case toc:
            delegate?.didTapTOCButton()
        case bookmark:
            delegate?.didTapBookmarkButton()
        case library:
            delegate?.didTapLibraryButton()
        case setting:
            delegate?.didTapSettingButton()
        default:
            return
        }
    }
    
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gesture: UILongPressGestureRecognizer) {
        switch sender {
        case back:
            delegate?.didLongPressBackButton()
        case forward:
            delegate?.didLongPressForwardButton()
        case bookmark:
            delegate?.didLongPressBookmarkButton()
        default:
            return
        }
    }
    
    @objc func tapped(button: UIBarButtonItem) {
        guard button == cancel else {return}
        delegate?.didTapCancelButton()
    }
}

protocol ButtonDelegates {
    func didTapBackButton()
    func didTapForwardButton()
    func didTapTOCButton()
    func didTapBookmarkButton()
    func didTapLibraryButton()
    func didTapSettingButton()
    func didTapCancelButton()
    
    func didLongPressBackButton()
    func didLongPressForwardButton()
    func didLongPressBookmarkButton()
}
