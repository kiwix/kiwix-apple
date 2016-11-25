//
//  ToolbarController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class Buttons: LPTBarButtonItemDelegate {
    
    private(set) lazy var back: UIBarButtonItem = LPTBarButtonItem(imageName: "LeftArrow", scale: 0.8, delegate: self)
    private(set) lazy var forward: UIBarButtonItem = LPTBarButtonItem(imageName: "RightArrow", scale: 0.8, delegate: self)
    private(set) lazy var toc: UIBarButtonItem = LPTBarButtonItem(imageName: "TableOfContent", scale: 0.8, delegate: self)
    private(set) lazy var bookmark: UIBarButtonItem = LPTBarButtonItem(imageName: "Bookmark", scale: 0.9, delegate: self)
    private(set) lazy var library: UIBarButtonItem = LPTBarButtonItem(imageName: "Library", delegate: self)
    private(set) lazy var setting: UIBarButtonItem = LPTBarButtonItem(imageName: "Setting", delegate: self)
    
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
    func didTapCancelButton()
    
    func didLongPressBackButton()
    func didLongPressForwardButton()
    func didLongPressBookmarkButton()
}
