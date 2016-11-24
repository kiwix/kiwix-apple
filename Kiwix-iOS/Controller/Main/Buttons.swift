//
//  ToolbarController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class Buttons {
    
    private(set) lazy var back: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "LeftArrow"), style: .plain,
                                                                  target: self, action: #selector(tapped(button:)))
    private(set) lazy var forward: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "RightArrow"), style: .plain,
                                                                   target: self, action: #selector(tapped(button:)))
    private(set) lazy var toc: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "TableOfContent"), style: .plain,
                                                                   target: self, action: #selector(tapped(button:)))
    private(set) lazy var bookmark: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "Bookmark"), style: .plain,
                                                                   target: self, action: #selector(tapped(button:)))
    private(set) lazy var library: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "Library"), style: .plain,
                                                                   target: self, action: #selector(tapped(button:)))
    private(set) lazy var setting: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "Setting"), style: .plain,
                                                                   target: self, action: #selector(tapped(button:)))
    
    private(set) lazy var cancel: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tapped(button:)))
    
    let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace)
    
    let testB = BarButton()
    var delegate: ButtonDelegates?
    
    var toolbar: [UIBarButtonItem] {
        get {
            return [testB, space, toc, space, bookmark, space, library, space, setting]
        }
    }
    
    var navLeft: [UIBarButtonItem] {
        get {
            return [back, forward, toc]
        }
    }
    
    var navRight: [UIBarButtonItem] {
        get {
            return [setting, library, bookmark]
        }
    }
    
    func addLongTapGestureRecognizer() {
        [back, forward, toc, bookmark, library, setting].enumerated().forEach { (index, button) in
            guard let view = button.value(forKey: "view") as? UIView else {return}
            view.tag = index
            view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(pressed(recognizer:))))
        }
    }
    
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

class GrayBarButtonItem: UIBarButtonItem {
    override init() {
        super.init()
        print(value(forKey: "view") as? UIView)
        tintColor = UIColor.gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print(value(forKey: "view") as? UIView)
        tintColor = UIColor.gray
    }
    
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
