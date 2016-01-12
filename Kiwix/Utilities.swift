//
//  Utilities.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class Utilities: NSObject {
    class func availableDiskspaceInBytes() -> Int64? {
        do {
            let systemAttributes = try NSFileManager.defaultManager().attributesOfFileSystemForPath(NSFileManager.docDirPath)
            guard let freeSize = systemAttributes[NSFileSystemFreeSize] as? NSNumber else {return nil}
            return freeSize.longLongValue
        } catch let error as NSError {
            print("Fetch system disk free space failed, error: \(error.localizedDescription)")
        }
        return nil
    }
    
    class func truncatedPlaceHolderString(string: String?, searchBar: UISearchBar) -> String? {
        if let string = string, let label = searchBar.valueForKey("_searchField")?.valueForKey("_placeholderLabel") as? UILabel, let labelFont = label.font {
            let preferredSize = CGSizeMake(searchBar.frame.width - 45.0, 1000)
            var rect = (string as NSString).boundingRectWithSize(preferredSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
            
            var truncatedString = string as NSString
            var istruncated = false
            while rect.height > label.frame.height {
                istruncated = true
                truncatedString = truncatedString.substringToIndex(truncatedString.length - 2)
                rect = truncatedString.boundingRectWithSize(preferredSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
            }
            return truncatedString as String + (istruncated ? "..." : "")
        }
        return nil
    }
    
    class func contentOfFileAtPath(path: String) -> String? {
        do {
            return try String(contentsOfFile: path)
        } catch {
            return nil
        }
    }
}