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
        var preferredLangCodes = NSMutableOrderedSet()
        for lang in preferredLangNames {
            guard let code = lang.componentsSeparatedByString("-").first else {continue}
            preferredLangCodes.addObject(NSLocale.canonicalLanguageIdentifierFromString(code))
        }
        return preferredLangCodes.flatMap({ $0 as? String})
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

extension UIDevice {
    class var availableDiskSpace: (freeSize: Int64, totalSize: Int64)? {
        let docDirPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        guard let systemAttributes = try? NSFileManager.defaultManager().attributesOfFileSystemForPath(docDirPath) else {return nil}
        guard let freeSize = systemAttributes[NSFileSystemFreeSize] as? Int64,
            let totalSize = systemAttributes[NSFileSystemSize] as? Int64 else {return nil}
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

