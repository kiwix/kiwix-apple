//
//  Preference.swift
//  Kiwix
//
//  Created by Chris Li on 8/2/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class Preference {
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
                NSUserDefaults.standardUserDefaults().setDouble(3600.0, forKey: "libraryRefreshInterval")
                NSUserDefaults.standardUserDefaults().synchronize()
                interval = 3600.0
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
}
