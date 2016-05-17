//
//  FileManager.swift
//  Kiwix
//
//  Created by Chris Li on 3/28/16.
//  Copyright © 2016 Chris. All rights reserved.
//

class FileManager {
    
    // MARK: - Path Utilities
    
    class var docDirPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return paths.first!
    }
    
    class var docDirURL: NSURL {
        return NSURL(fileURLWithPath: docDirPath, isDirectory: true)
    }
    
    class var libDirPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
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
    
    private class func resumeDataURL(book: Book) -> NSURL {
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
            removeItem(atURL: resumeDataURL(book))
        }
    }
    
    // MARK: - General File Operations
    
    class func fileExistAtURL(url: NSURL) -> Bool {
        guard let path = url.path else {return false}
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }
    
    class func removeItem(atURL location: NSURL) -> Bool {
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
            succeed = removeItem(atURL: toURL)
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
    
    class func contentsOfDirectory(url: NSURL) -> [NSURL] {
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants)
        } catch let error as NSError {
            print("Contents of Directory failed: \(error.localizedDescription)")
            return [NSURL]()
        }
    }
    
    class func removeContentsOfDirectory(url: NSURL) {
        for fileURL in contentsOfDirectory(url) {
            removeItem(atURL: fileURL)
        }
    }
}
