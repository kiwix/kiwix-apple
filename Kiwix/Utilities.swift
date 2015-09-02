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
    
    class func articlePathComponents(path: String) -> (idString: String, articleTitle: String) {
        var components = path.componentsSeparatedByString("/")
        let idString = components.first ?? ""
        components.removeFirst()
        let articleTitle = components.joinWithSeparator("/")
        return (idString, articleTitle)
    }
    
    // MARK: - Color
    
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
        if let reader = ZimMultiReader.sharedInstance.allLocalZimFileReader[book.idString!] {
            print(reader.fileURL())
            return reader.fileURL()
        } else {
            let fileName = ((book.meta4URL as! NSString).pathComponents.last as! NSString).stringByReplacingOccurrencesOfString(".meta4", withString: "")
            let location = NSURL(fileURLWithPath: docDirPath()).URLByAppendingPathComponent(fileName, isDirectory: false)
            return location
        }
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
            return true
        } catch let error as NSError {
            // failure
            print("Delete File failed: \(error.localizedDescription)")
            return false
        }
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
        data.writeToURL(resumeDataURL(book), atomically: true)
        print(resumeDataURL(book))
    }
    
    class func readResumeData(book: Book) -> NSData? {
        if let path = resumeDataURL(book).path {
            return NSFileManager.defaultManager().contentsAtPath(path)
        } else {
            return nil
        }
    }
    
    class func removeResumeData(book: Book) {
        if NSFileManager.defaultManager().fileExistsAtPath(resumeDataURL(book).path!) {
            removeFile(AtLocation: resumeDataURL(book))
        }
    }
    
    class func resumeDataURL(book: Book) -> NSURL {
        let tempDownloadLocation = NSURL(fileURLWithPath: libDirPath()).URLByAppendingPathComponent("DownloadTemp", isDirectory: true)
        return tempDownloadLocation.URLByAppendingPathComponent(book.idString!, isDirectory: false)
    }
    
    class func contentsOfDocDir() -> [String]? {
        do {
            let fileNames = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.docDirPath())
            return fileNames
        } catch let error as NSError {
            // failure
            print("Get Contents Of Doc Dir failed: \(error.localizedDescription)")
            return nil
        }
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
    
    class func tableHeaderFooterView(withMessage message: String, preferredWidth width: CGFloat, textAlientment: NSTextAlignment) -> UIView {
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
        let horizontalInset = 14.0 as CGFloat
        let verticalInset = 20.0 as CGFloat
        let estimatedSize = CGSizeMake(width - 2*horizontalInset, 2000.0)
        let labelRect = (message as NSString).boundingRectWithSize(estimatedSize, options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        let label = UILabel(frame: CGRectMake((width-labelRect.size.width)/2, verticalInset, labelRect.size.width, labelRect.size.height))
        label.text = message
        label.textColor = UIColor.darkGrayColor()
        label.opaque = false
        label.numberOfLines = 0
        label.font = font
        label.textAlignment = textAlientment
        let view = UIView(frame: CGRectMake(0, 0, width, labelRect.size.height+verticalInset*2))
        view.addSubview(label)
        return view
    }
    
    // MARK: - Preferred Language
    
    class func isoLangCodes() -> Dictionary<String, String> {
        let isoLangCodesURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("ISOLangCode", ofType: "plist")!)
        return NSDictionary (contentsOfURL: isoLangCodesURL) as! Dictionary<String, String>
    }
    
    class func preferredLanguage() -> [String] {
        let preferredLanguageDescs = NSLocale.preferredLanguages()
        let isoLangCodes = self.isoLangCodes()
        var preferredLanguage = [String]()
        
        for languageDesc in preferredLanguageDescs {
            if let langCode = languageDesc.componentsSeparatedByString("-").first {
                if Array(isoLangCodes.keys).contains(langCode) {
                    if let langName = isoLangCodes[langCode] {
                        preferredLanguage.append(langName)
                    }
                }
            }
        }
        return preferredLanguage
    }
    
    class func preferredLanguagePromptMessage(var languages: [String]) -> String {
        let lastLanguage = languages.last ?? ""
        languages.removeLast()
        let languageConcatenated: String = {
            if languages.count == 0 {
                return lastLanguage
            } else {
                return languages.joinWithSeparator(", ") + " and " + lastLanguage
            }
        }()
        
        return "We have found you may know " + languageConcatenated + ", would you like to filter the catalogue by these languages?"
    }
    
    // MARK: - Application Icon Badge Number
    class func updateApplicationIconBadgeNumber() {
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if settings.types.contains(UIUserNotificationType.Badge) {
                UIApplication.sharedApplication().applicationIconBadgeNumber = Downloader.sharedInstance.urlSessionDic.count
            }
        }
    }
}