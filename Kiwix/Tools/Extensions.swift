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
        // Reason for use NSMutableOrderedSet, there might be slight variation of the same language, e.g. en-US & en-UK, we want en to only appear once
        let codes = NSMutableOrderedSet()
        preferredLanguages().forEach { (string) in
            guard let code = string.componentsSeparatedByString("-").first else {return}
            codes.addObject(NSLocale.canonicalLanguageIdentifierFromString(code))
        }
        return codes.flatMap({ $0 as? String})
    }
    
    class var preferredLangNames: [String] {
        // Reason for use NSMutableOrderedSet, there might be slight variation of the same language, e.g. en-US & en-UK, we want en to only appear once 
        let names = NSMutableOrderedSet()
        preferredLanguages().forEach { (string) in
            guard let code = string.componentsSeparatedByString("-").first,
                let name = NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: code) else {return}
            names.addObject(name)
        }
        return names.flatMap({ $0 as? String})
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
    
    class var cacheDirURL: NSURL {
        let url = try? NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
        return url!
    }
    
    class func getContents(dir dir: NSURL) -> [NSURL] {
        let options: NSDirectoryEnumerationOptions = [.SkipsHiddenFiles, .SkipsPackageDescendants, .SkipsSubdirectoryDescendants]
        let urls = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSFileManager.docDirURL, includingPropertiesForKeys: nil, options: options)
        return urls ?? [NSURL]()
    }
}

extension UIDevice {
    class var availableDiskSpace: (freeSize: Int64, totalSize: Int64)? {
        let docDirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        guard let systemAttributes = try? NSFileManager.defaultManager().attributesOfFileSystemForPath(docDirPath),
            let freeSize = (systemAttributes[NSFileSystemFreeSize] as? NSNumber)?.longLongValue,
            let totalSize = (systemAttributes[NSFileSystemSize] as? NSNumber)?.longLongValue else {return nil}
        return (freeSize, totalSize)
    }
}

extension CollectionType {
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Swift 3
//extension IndexableBase {
//    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
//    public subscript(safe index: Index) -> _Element? {
//        return index >= startIndex && index < endIndex
//            ? self[index]
//            : nil
//    }
//}

