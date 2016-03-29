//
//  NSFileManager+.swift
//  Grid
//
//  Created by Chris on 12/10/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension NSFileManager {
    
    // MARK: - Path Utilities
    
    class var docDirPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        return paths.first!
    }
    
    class var docDirURL: NSURL {
        return NSURL(fileURLWithPath: docDirPath, isDirectory: true)
    }
    
    class var libDirPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        return paths.first!
    }
    
    class var libDirURL: NSURL {
        return NSURL(fileURLWithPath: libDirPath, isDirectory: true)
    }
    
    // MARK: - Move Book
    
    class func move(book: Book, fromURL: NSURL, suggestedFileName: String?) {
        let fileName: String = {
            if let suggestedFileName = suggestedFileName {return suggestedFileName}
            if let id = book.id {return "\(id).zim"}
            return NSDate().description + ".zim"
        }()
        let directory = docDirURL
        createDirectory(directory, includeInICloudBackup: false)
        let destination = directory.URLByAppendingPathComponent(fileName)
        moveOrReplaceFile(from: fromURL, to: destination)
    }
    
    // MARK: - Book Resume Data
    
    class func resumeDataURL(book: Book) -> NSURL {
        let tempDownloadLocation = NSURL(fileURLWithPath: libDirPath).URLByAppendingPathComponent("DownloadTemp", isDirectory: true)
        return tempDownloadLocation.URLByAppendingPathComponent(book.id ?? NSDate().description, isDirectory: false)
    }
    
    class func saveResumeData(data: NSData, book: Book) {
        let tempDownloadLocation = NSURL(fileURLWithPath: libDirPath).URLByAppendingPathComponent("DownloadTemp", isDirectory: true)
        if !NSFileManager.defaultManager().fileExistsAtPath(tempDownloadLocation.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(tempDownloadLocation, withIntermediateDirectories: true, attributes: [NSURLIsExcludedFromBackupKey: true])
            } catch let error as NSError {
                print("Create temp download folder failed: \(error.localizedDescription)")
            }
        }
        data.writeToURL(resumeDataURL(book), atomically: true)
    }
    
    class func readResumeData(book: Book) -> NSData? {
        guard let path = resumeDataURL(book).path else {return nil}
        return NSFileManager.defaultManager().contentsAtPath(path)
    }
    
    class func removeResumeData(book: Book) {
        if NSFileManager.defaultManager().fileExistsAtPath(resumeDataURL(book).path!) {
            removeFile(atURL: resumeDataURL(book))
        }
    }
    
    // MARK: General Move File
    
    class func removeFile(atURL location: NSURL) -> Bool {
        var succeed = true
        do {
            try NSFileManager.defaultManager().removeItemAtURL(location)
        } catch let error as NSError {
            succeed = false
            print("Remove File failed: \(error.localizedDescription)")
        }
        return succeed
    }
    
    class func moveOrReplaceFile(from fromURL: NSURL, to toURL: NSURL) -> Bool {
        var succeed = true
        guard let path = toURL.path else {return false}
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            succeed = removeFile(atURL: toURL)
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(fromURL, toURL: toURL)
        } catch let error as NSError {
            succeed = false
            print("Move File failed: \(error.localizedDescription)")
        }
        return succeed
    }
    
    class func createDirectory(url: NSURL, includeInICloudBackup: Bool) {
        guard let path = url.path else {return}
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: [NSURLIsExcludedFromBackupKey: true])
        } catch let error as NSError {
            print("Create Directory failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Directory Contents
    
    class func contentsOfDirectoryAtURL(url: NSURL) -> [NSURL]? {
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: [NSURLFileResourceTypeKey], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
    
    class func zimFilesInDocDir() -> [NSURL] {
        let contents = contentsOfDirectoryAtURL(docDirURL) ?? [NSURL]()
        var zimFiles = [NSURL]()
        for url in contents {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if !isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension.containsString("zim") else {continue}
                        zimFiles.append(url)
                    }
                }
            } catch {
                continue
            }
        }
        return zimFiles
    }
}