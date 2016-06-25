//
//  Preference.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import SwiftyUserDefaults

class Preference {
    
    class var hasShowGetStartedAlert: Bool {
        get{return Defaults[.hasShowGetStartedAlert]}
        set{Defaults[.hasShowGetStartedAlert] = newValue}
    }
    
    // MARK: - Reading
    
    class var webViewZoomScale: Double {
        get{return Defaults[.webViewZoomScale] ?? 100.0}
        set{Defaults[.webViewZoomScale] = newValue}
    }
    
    class var webViewInjectJavascriptToAdjustPageLayout: Bool {
        get{return !Defaults[.webViewNotInjectJavascriptToAdjustPageLayout]}
        set{Defaults[.webViewNotInjectJavascriptToAdjustPageLayout] = !newValue}
    }
    
    // MARK: - Rate Kiwix
    
    class var activeUseHistory: [NSDate] {
        get{return Defaults[.activeUseHistory]}
        set{Defaults[.activeUseHistory] = newValue}
    }
    
    class var haveRateKiwix: Bool {
        get{return Defaults[.haveRateKiwix]}
        set{Defaults[.haveRateKiwix] = newValue}
    }
}

extension DefaultsKeys {
    static let hasShowGetStartedAlert = DefaultsKey<Bool>("hasShowGetStartedAlert")
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    static let webViewNotInjectJavascriptToAdjustPageLayout = DefaultsKey<Bool>("webViewNotInjectJavascriptToAdjustPageLayout")
    static let activeUseHistory = DefaultsKey<[NSDate]>("activeUseHistory")
    static let haveRateKiwix = DefaultsKey<Bool>("haveRateKiwix")
}