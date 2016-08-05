//
//  Extensions.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

// MARK: - App Delegate Accessor

#if os(iOS) || os(watchOS) || os(tvOS)
    extension UIApplication {
        class var appDelegate: AppDelegate {
            return UIApplication.sharedApplication().delegate as! AppDelegate
        }
    }
#elseif os(OSX)
    extension NSApplication {
        class var appDelegate: AppDelegate {
            return NSApplication.sharedApplication().delegate as! AppDelegate
        }
    }
#endif

extension NSLocale {
    class var preferredLangCodes: [String] {
        let preferredLangNames = self.preferredLanguages()
        var preferredLangCodes = Set<String>()
        for lang in preferredLangNames {
            guard let code = lang.componentsSeparatedByString("-").first else {continue}
            preferredLangCodes.insert(NSLocale.canonicalLanguageIdentifierFromString(code))
        }
        return Array(preferredLangCodes)
    }
}

extension NSBundle {
    class var appShortVersion: String {
        return (NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String) ?? ""
    }
    
    class var buildVersion: String {
        return (NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String) ?? "Unknown"
    }
}

extension NSFileManager {
    class var docDirURL: NSURL {
        let url = try? NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        return url!
    }
    
    class var libDirURL: NSURL {
        let url = try? NSFileManager.defaultManager().URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        return url!
    }
    
    class func getContents(dir dir: NSURL) -> [NSURL] {
        let options: NSDirectoryEnumerationOptions = [.SkipsHiddenFiles, .SkipsPackageDescendants, .SkipsSubdirectoryDescendants]
        let urls = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSFileManager.docDirURL, includingPropertiesForKeys: nil, options: options)
        return urls ?? [NSURL]()
    }
}


