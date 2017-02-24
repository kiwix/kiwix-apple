//
//  iOSExtensions.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

// MARK: - UI

enum BuildStatus {
    case alpha, beta, release
}

extension UIApplication {
    class var buildStatus: BuildStatus {
        get {
            return .beta
        }
    }
}

class AppColors {
    static let hasPicTintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    static let hasIndexTintColor = UIColor(red: 0.304706, green: 0.47158, blue: 1, alpha: 1)
    static let theme = UIColor(red: 71/255, green: 128/255, blue: 182/255, alpha: 1)
}

extension Locale {
    static var preferredLangCodes: [String] {
        // Reason for use NSMutableOrderedSet, there might be slight variation of the same language, e.g. en-US & en-UK, we want en to only appear once
        let codes = NSMutableOrderedSet()
        preferredLanguages.forEach { (string) in
            guard let code = string.components(separatedBy: "-").first else {return}
            codes.add(Locale.canonicalLanguageIdentifier(from: code))
        }
        return codes.flatMap({ $0 as? String})
    }
    
    static var preferredLangNames: [String] {
        // Reason for use NSMutableOrderedSet, there might be slight variation of the same language, e.g. en-US & en-UK, we want en to only appear once
        let names = NSMutableOrderedSet()
        preferredLanguages.forEach { (string) in
            guard let code = string.components(separatedBy: "-").first,
                let name = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: code) else {return}
            names.add(name)
        }
        return names.flatMap({ $0 as? String})
    }
}

extension Bundle {
    class var appShortVersion: String {
        return (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
    }
    
    class var buildVersion: String {
        return (Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String) ?? "Unknown"
    }
}

extension UIDevice {
    class var hasCellularCapability: Bool {
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                ptr = ptr!.pointee.ifa_next
                let ifaName = String(utf8String: ptr!.pointee.ifa_name)
                if ifaName == "pdp_ip0" {return true}
            }
        }
        return false
    }
}
