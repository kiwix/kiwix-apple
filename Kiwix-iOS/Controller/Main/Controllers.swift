//
//  Controllers.swift
//  Kiwix
//
//  Created by Chris Li on 11/15/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class Controllers {
    
    public func cleanUp() {
        //_bookmark = nil
        //bookmarkHUD = nil
        _library = nil
        _search = nil
        //setting = nil
        _welcome = nil
    }
    
    // MARK: - Main
    
    class var main: MainController {
        return (UIApplication.appDelegate.window?.rootViewController as! UINavigationController).topViewController as! MainController
    }
    
    // MARK: - Web
    
    lazy private(set) var web = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
    
//    // MARK: - Bookmark
//    
//    private var bookmark: UINavigationController?
//    
//    class var bookmark: UINavigationController {
//        let controller = Controllers.shared.bookmark ?? UIStoryboard(name: "Bookmark", bundle: nil).instantiateInitialViewController() as! UINavigationController
//        Controllers.shared.bookmark = controller
//        return controller
//    }
//    
//    private var bookmarkHUD: BookmarkHUD?
//    
//    class var bookmarkHUD: BookmarkHUD {
//        let controller = Controllers.shared.bookmarkHUD ?? UIStoryboard(name: "Bookmark", bundle: nil).instantiateViewController(withIdentifier: "BookmarkHUD") as! BookmarkHUD
//        Controllers.shared.bookmarkHUD = controller
//        return controller
//    }
    
    // MARK: - Library
    
    private var _library: UIViewController?
    var library: UIViewController {
        let controller = _library ?? UIStoryboard(name: "Library", bundle: nil).instantiateInitialViewController()!
        _library = controller
        return controller
    }
    
    // MARK: -  Search
    
    private var _search: SearchContainer?
    var search: SearchContainer {
        let controller = _search ?? UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as! SearchContainer
        _search = controller
        return controller
    }
//    
//    // MARK: - Setting
//    
//    private var setting: UIViewController?
//    
//    class var setting: UIViewController {
//        let controller = Controllers.shared.setting ?? UIStoryboard(name: "Setting", bundle: nil).instantiateInitialViewController()!
//        Controllers.shared.setting = controller
//        return controller
//    }
    
    // MARK: - Welcome
    
    private var _welcome: WelcomeController?
    var welcome: WelcomeController {
        let controller = _welcome ?? UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController() as! WelcomeController
        _welcome = controller
        return controller
    }
    
}
