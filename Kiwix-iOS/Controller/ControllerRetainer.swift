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
        search = nil
        bookmark = nil
    }
    
    // MARK: -  Search
    
    private var search: SearchController?
    
    class var search: SearchController {
        let controller = ControllerRetainer.shared.search ?? UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as! SearchController
        ControllerRetainer.shared.search = controller
        return controller
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
        let controller = ControllerRetainer.shared.bookmarkStar ?? UIStoryboard(name: "Library", bundle: nil).instantiateInitialViewController()
        ControllerRetainer.shared.library = controller!
        return controller!
    }
}
