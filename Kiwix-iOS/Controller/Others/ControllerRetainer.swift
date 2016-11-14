//
//  Controllers.swift
//  Kiwix
//
//  Created by Chris Li on 8/31/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class Controllers {
    static let shared = Controllers()
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(Controllers.removeStrongReference), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    @objc private func removeStrongReference() {
        bookmark = nil
        bookmarkHUD = nil
        library = nil
        search = nil
        setting = nil
        welcome = nil
    }
    
    // MARK: - Main
    
    class var main: MainController {
        return (UIApplication.appDelegate.window?.rootViewController as! UINavigationController).topViewController as! MainController
    }
    
    // MARK: - Bookmark
    
    private var bookmark: UINavigationController?
    
    class var bookmark: UINavigationController {
        let controller = Controllers.shared.bookmark ?? UIStoryboard(name: "Bookmark", bundle: nil).instantiateInitialViewController() as! UINavigationController
        Controllers.shared.bookmark = controller
        return controller
    }
    
    private var bookmarkHUD: BookmarkHUD?
    
    class var bookmarkHUD: BookmarkHUD {
        let controller = Controllers.shared.bookmarkHUD ?? UIStoryboard(name: "Bookmark", bundle: nil).instantiateViewController(withIdentifier: "BookmarkHUD") as! BookmarkHUD
        Controllers.shared.bookmarkHUD = controller
        return controller
    }
    
    // MARK: - Library
    
    private var library: UIViewController?
    
    class var library: UIViewController {
        let controller = Controllers.shared.library ?? UIStoryboard(name: "Library", bundle: nil).instantiateInitialViewController()!
        Controllers.shared.library = controller
        return controller
    }
    
    
    // MARK: -  Search
    
    private var search: SearchContainer?
    
    class var search: SearchContainer {
        let controller = Controllers.shared.search ??
            UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as! SearchContainer
        Controllers.shared.search = controller
        return controller
    }
    
    // MARK: - Setting
    
    private var setting: UIViewController?
    
    class var setting: UIViewController {
        let controller = Controllers.shared.setting ?? UIStoryboard(name: "Setting", bundle: nil).instantiateInitialViewController()!
        Controllers.shared.setting = controller
        return controller
    }
    
    // MARK: - Welcome
    
    private var welcome: WelcomeController?
    
    class var welcome: WelcomeController {
        let controller = Controllers.shared.welcome ?? UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController() as! WelcomeController
        Controllers.shared.welcome = controller
        return controller
    }
    
}
