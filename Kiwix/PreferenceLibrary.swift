//
//  PreferenceLibrary.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension Preference {
    
    // MARK: - Auto Refresh
    
    class var libraryAutoRefreshDisabled: Bool {
        get{return Defaults[.libraryAutoRefreshDisabled]}
        set{Defaults[.libraryAutoRefreshDisabled] = newValue}
    }
    
    class var libraryRefreshAllowCellularData: Bool {
        get{return !Defaults[.libraryRefreshNotAllowCellularData]}
        set{Defaults[.libraryRefreshNotAllowCellularData] = !newValue}
    }
    
    // MARK: - Refresh Time
    
    class var libraryLastRefreshTime: NSDate? {
        get{return Defaults[.libraryLastRefreshTime]}
        set{Defaults[.libraryLastRefreshTime] = newValue}
    }
    
    class var libraryRefreshInterval: NSTimeInterval {
        get{return Defaults[.libraryRefreshInterval] ?? 3600.0 * 24}
        set{Defaults[.libraryRefreshInterval] = newValue}
    }
    
    // MARK: - Prompt
    
    class var libraryHasShownPreferredLanguagePrompt: Bool {
        get{return Defaults[.libraryHasShownPreferredLanguagePrompt]}
        set{Defaults[.libraryHasShownPreferredLanguagePrompt] = newValue}
    }

}

extension DefaultsKeys {
    static let libraryAutoRefreshDisabled = DefaultsKey<Bool>("libraryAutoRefreshDisabled")
    static let libraryRefreshNotAllowCellularData = DefaultsKey<Bool>("libraryRefreshNotAllowCellularData")
    static let libraryLastRefreshTime = DefaultsKey<NSDate?>("libraryLastRefreshTime")
    static let libraryRefreshInterval = DefaultsKey<Double?>("libraryRefreshInterval")
    static let libraryHasShownPreferredLanguagePrompt = DefaultsKey<Bool>("libraryHasShownPreferredLanguagePrompt")
}