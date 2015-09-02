//
//  Preference.swift
//  Kiwix
//
//  Created by Chris Li on 8/2/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

enum WebViewHomePage: Int {
    case Blank
    case Random
    case MainPage
}

class Preference {
    
    // MARK: - Version
    
    class var versionNumber: Double {
        get {
            return NSUserDefaults.standardUserDefaults().doubleForKey("versionNumber") as Double
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue, forKey: "versionNumber")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // MARK: - Downloader 
    
    class var downloaderAllowCellularData: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("downloaderAllowCellularData")
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "downloaderAllowCellularData")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // MARK: - Library Refresh
    
    class var libraryLastRefreshTime: NSDate? {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("libraryLastRefreshTime") as? NSDate
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "libraryLastRefreshTime")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var libraryRefreshInterval: NSTimeInterval {
        get {
            var interval = NSUserDefaults.standardUserDefaults().doubleForKey("libraryRefreshInterval")
            if interval == 0.0 {
                NSUserDefaults.standardUserDefaults().setDouble(3600.0 * 24.0, forKey: "libraryRefreshInterval")
                NSUserDefaults.standardUserDefaults().synchronize()
                interval = 3600.0 * 24.0
            }
            return interval
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue, forKey: "libraryRefreshInterval")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var libraryAutoRefreshDisabled: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("libraryAutoRefreshDisabled")
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "libraryAutoRefreshDisabled")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var libraryFilteredLanguages: [String]? {
        get {
            return NSUserDefaults.standardUserDefaults().arrayForKey("libraryFilteredLanguages") as? [String]
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "libraryFilteredLanguages")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var libraryHasShownPreferredLanguagePrompt: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("libraryHasShownPreferredLanguagePrompt")
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "libraryHasShownPreferredLanguagePrompt")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // MARK: - UIWebView
    
    class var webViewZoomScale: Double {
        get {
            var scale = NSUserDefaults.standardUserDefaults().doubleForKey("webViewZoomScale")
            if scale == 0.0 {
                scale = 100.0
            }
            return scale
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue, forKey: "webViewZoomScale")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var webViewScalePageToFitWidth: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("webViewScalePageToFitWidth")
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "webViewScalePageToFitWidth")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var webViewHomePage: WebViewHomePage? {
        get {
            return WebViewHomePage(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("webViewHomePage"))
        }
        set {
            let rawValue = newValue?.rawValue ?? 0
            NSUserDefaults.standardUserDefaults().setInteger(rawValue, forKey: "webViewHomePage")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    class var webViewHomePageBookID: String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("webViewHomePageBookID")
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "webViewHomePageBookID")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
}
