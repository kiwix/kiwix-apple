//
//  Extensions.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation
import UIKit

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
    class var availableDiskSpace: (freeSize: Int64, totalSize: Int64)? {
        let docDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: docDirPath),
            let freeSize = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value,
            let totalSize = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else {return nil}
        return (freeSize, totalSize)
    }
}


