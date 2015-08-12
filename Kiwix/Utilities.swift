//
//  Utilities.swift
//  Kiwix
//
//  Created by Chris Li on 8/3/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class Utilities {
    
    //MARK: - Path Utilities
    
    class func docDirPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        return paths.first!
    }
    
    class func libDirPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        return paths.first!
    }
    
    class func isoLangCodes() -> Dictionary<String, String> {
        let isoLangCodesURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("ISOLangCode", ofType: "plist")!)
        return NSDictionary (contentsOfURL: isoLangCodesURL) as! Dictionary<String, String>
    }
    
    class func customTintColor() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 153.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    }
    
    // MARK: - String methods
    
    class func formattedDateStringFromDate(date: NSDate) -> String {
        let dateFormater = NSDateFormatter()
        dateFormater.dateFormat = "MM-dd-yyyy"
        dateFormater.dateStyle = .MediumStyle
        return dateFormater.stringFromDate(date)
    }
    
    class func formattedFileSizeStringFromByteCount(fileBytes: Int64) -> String {
        return NSByteCountFormatter.stringFromByteCount(fileBytes, countStyle: .File)
    }
    
    class func formattedNumberStringFromInt(number: Int32) -> String {
        return OldObjcMethods.abbreviateNumber(number)
    }
    
    // MARK: - File management
    
    class func availableDiskspaceInBytes() -> Int64 {
        let availableBytes = OldObjcMethods.getFreeDiskspaceInBytes()
        return Int64(availableBytes)
    }
    private class func removeFile(AtLocation location: NSURL) -> Bool {
        var succeed = true
        do {
            try NSFileManager.defaultManager().removeItemAtURL(location)
        } catch let error as NSError {
            // failure
            succeed = false
            print("Remove File failed: \(error.localizedDescription)")
        }
        return succeed
    }
    
    private class func moveFileFrom(fromLocation: NSURL, toLocation: NSURL) -> Bool {
        var succeed = true
        if NSFileManager.defaultManager().fileExistsAtPath(toLocation.path!) {
            succeed = removeFile(AtLocation: toLocation)
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(fromLocation, toURL: toLocation)
        } catch let error as NSError {
            // failure
            succeed = false
            print("Move File failed: \(error.localizedDescription)")
        }
        return succeed
    }
    
    private class func bookURLInDocDir(book: Book) -> NSURL {
        let fileName = ((book.meta4URL as! NSString).pathComponents.last as! NSString).stringByReplacingOccurrencesOfString(".meta4", withString: "")
        let location = NSURL(fileURLWithPath: docDirPath()).URLByAppendingPathComponent(fileName, isDirectory: false)
        return location
    }
    
    class func moveDownloadedBook(book: Book, toDocDirFromLocation fromLocation: NSURL) {
        let toLocation = bookURLInDocDir(book)
        if moveFileFrom(fromLocation, toLocation: toLocation) {
            book.localURL = toLocation.absoluteString
        }
    }
    
    class func removeBookFromDisk(book: Book) -> Bool {
        let location = bookURLInDocDir(book)
        do {
            try NSFileManager.defaultManager().removeItemAtURL(location)
        } catch let error as NSError {
            // failure
            print("Delete File failed: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    class func saveResumeData(data: NSData, book: Book) {
        let tempDownloadLocation = NSURL(fileURLWithPath: libDirPath()).URLByAppendingPathComponent("DownloadTemp", isDirectory: true)
        if !NSFileManager.defaultManager().fileExistsAtPath(tempDownloadLocation.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(tempDownloadLocation, withIntermediateDirectories: true, attributes: [NSURLIsExcludedFromBackupKey: true])
            } catch let error as NSError {
                // failure
                print("Create temp download folder failed: \(error.localizedDescription)")
            }
        }
        let tempFileURL = tempDownloadLocation.URLByAppendingPathComponent(book.idString!, isDirectory: false)
        data.writeToURL(tempFileURL, atomically: true)
    }
    
    class func readResumeData(book: Book) -> NSData? {
        let tempDownloadLocation = NSURL(fileURLWithPath: libDirPath()).URLByAppendingPathComponent("DownloadTemp", isDirectory: true)
        let tempFileURL = tempDownloadLocation.URLByAppendingPathComponent(book.idString!, isDirectory: false)
        return NSData(contentsOfURL: tempFileURL)
    }
    
    class func removeResumeData(book: Book) {
        let tempDownloadLocation = NSURL(fileURLWithPath: libDirPath()).URLByAppendingPathComponent("DownloadTemp", isDirectory: true)
        let tempFileURL = tempDownloadLocation.URLByAppendingPathComponent(book.idString!, isDirectory: false)
        removeFile(AtLocation: tempDownloadLocation)
    }
    
    // MARK: - Alert
    
    class func alertWith(title: String, message: String, actions:[UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message , preferredStyle: .Alert)
        for action in actions {
            alert.addAction(action)
        }
        return alert
    }
    
    // MARK: - Views
    
    class func tableHeaderFooterView(withMessage message: String, andPreferredWidth width: CGFloat) -> UIView {
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        let horizontalInset = 20.0 as CGFloat
        let verticalInset = 20.0 as CGFloat
        let estimatedSize = CGSizeMake(width - 2*horizontalInset, 2000.0)
        let labelRect = (message as NSString).boundingRectWithSize(estimatedSize, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        let label = UILabel(frame: CGRectMake((width-labelRect.size.width)/2, verticalInset, labelRect.size.width, labelRect.size.height))
        label.text = message
        label.textColor = UIColor.darkGrayColor()
        label.opaque = false
        label.numberOfLines = 0
        label.font = font
        label.textAlignment = .Center
        let view = UIView(frame: CGRectMake(0, 0, width, labelRect.size.height+verticalInset*2))
        view.addSubview(label)
        return view
    }
}