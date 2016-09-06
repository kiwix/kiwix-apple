//
//  ControllerRetainer.swift
//  Kiwix
//
//  Created by Chris Li on 8/31/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class ControllerRetainer {
    static let shared = ControllerRetainer()
    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ControllerRetainer.removeStrongReference), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc func removeStrongReference() {
        bookmark = nil
        bookmarkStar = nil
        library = nil
        search = nil
        setting = nil
        welcome = nil
    }
    
    // MARK: - Bookmark
    
    private var bookmark: UINavigationController?
    
    class var bookmark: UINavigationController {
        let controller = ControllerRetainer.shared.bookmark ?? UIStoryboard(name: "Bookmark", bundle: nil).instantiateInitialViewController() as! UINavigationController
        ControllerRetainer.shared.bookmark = controller
        return controller
    }
    
    private var bookmarkStar: BookmarkController?
    
    class var bookmarkStar: BookmarkController {
        let controller = ControllerRetainer.shared.bookmarkStar ?? UIStoryboard(name: "Bookmark", bundle: nil).instantiateViewControllerWithIdentifier("BookmarkController") as! BookmarkController
        ControllerRetainer.shared.bookmarkStar = controller
        return controller
    }
    
    // MARK: - Library
    
    private var library: UIViewController?
    
    class var library: UIViewController {
        let controller = ControllerRetainer.shared.bookmarkStar ?? UIStoryboard(name: "Library", bundle: nil).instantiateInitialViewController()!
        ControllerRetainer.shared.library = controller
        return controller
    }
    
    // MARK: -  Search
    
    private var search: SearchController?
    
    class var search: SearchController {
        let controller = ControllerRetainer.shared.search ?? UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as! SearchController
        ControllerRetainer.shared.search = controller
        return controller
    }
    
    // MARK: - Setting
    
    private var setting: UIViewController?
    
    class var setting: UIViewController {
        let controller = ControllerRetainer.shared.setting ?? UIStoryboard(name: "Setting", bundle: nil).instantiateInitialViewController()!
        ControllerRetainer.shared.setting = controller
        return controller
    }
    
    // MARK: - Welcome
    
    private var welcome: UIViewController?
    
    class var welcome: UIViewController {
        let controller = ControllerRetainer.shared.welcome ?? UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController()!
        ControllerRetainer.shared.welcome = controller
        return controller
    }
    
}
