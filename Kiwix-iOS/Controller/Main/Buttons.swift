//
//  ToolbarController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/16.
//  Copyright © 2016 Wikimedia CH. All rights reserved.
//

import UIKit

class Buttons {
    
    private(set) lazy var left: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "LeftArrow"), style: .plain,
                                                                  target: self, action: #selector(tapped(button:)))
    private(set) lazy var right: UIBarButtonItem = GrayBarButtonItem(image: UIImage(named: "RightArrow"), style: .plain,
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
    var delegate: ButtonDelegates?
    
    var toolbar: [UIBarButtonItem] {
        get {
            return [left, space, right, space, toc, space, bookmark, space, library, space, setting]
        }
    }
    
    var navLeft: [UIBarButtonItem] {
        get {
            return [left, right, toc]
        }
    }
    
    var navRight: [UIBarButtonItem] {
        get {
            return [setting, library, bookmark]
        }
    }
    
    func addLongTapGestureRecognizer() {
        [left, right, toc, bookmark, library, setting].enumerated().forEach { (index, button) in
            guard let view = button.value(forKey: "view") as? UIView else {return}
            view.tag = index
            view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(pressed(recognizer:))))
        }
    }
    
    @objc func tapped(button: UIBarButtonItem) {
        switch button {
        case left:
            print("left tapped")
        case right:
            print("right tapped")
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
            print("left long tapped")
        case 1:
            print("right long tapped")
        default:
            return
        }
    }
}

protocol ButtonDelegates {
    
    func didTapLibraryButton()
    func didTapCancelButton()
}

class GrayBarButtonItem: UIBarButtonItem {
    override init() {
        super.init()
        tintColor = UIColor.gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tintColor = UIColor.gray
    }
}
