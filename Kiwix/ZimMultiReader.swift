//
//  ZIMMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class ZIMMultiReader: NSObject, DirectoryMonitorDelegate {
    
    static let sharedInstance = ZIMMultiReader()
    private(set) var readers = [String: ZimReader]()
    let searchQueue = OperationQueue()
    
    private let monitor = DirectoryMonitor(URL: NSFileManager.docDirURL)
    private var zimURLs = Set<NSURL>()
    private var zimAdded = Set<NSURL>()
    private var zimRemoved = Set<NSURL>()
    private var indexFolders = Set<NSURL>()
    
    override init() {
        super.init()
        monitor.delegate = self
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        let operation = RescanZimMultiReaderOperation()
        UIApplication.globalOperationQueue.addOperation(operation)
    }
    
    // MARK: - Refresh
    
    func rescan() {
        // If list of idx folder changed, remove all items in zimURLs
        // It is equivalent to reinitialize all ZimReader for every zim file.
        let newIndexFolders = Set(indexFolderURLsInDocDir)
        if newIndexFolders != indexFolders {
            zimURLs.removeAll()
        }
        indexFolders = newIndexFolders
        
        // Below are the lines required when not considering idx folders, aka only detect zim files
        let newZimURLs = Set(zimFileURLsInDocDir)
        zimAdded = newZimURLs.subtract(zimURLs)
        zimRemoved = zimURLs.subtract(newZimURLs)
        removeOld()
        addNew()
        zimAdded.removeAll()
        zimRemoved.removeAll()
        zimURLs = newZimURLs
    }
    
    private func removeOld() {
        for (id, reader) in readers {
            guard zimRemoved.contains(reader.fileURL) else {continue}
            readers[id] = nil
            
            guard let book = Book.fetch(id, context: UIApplication.appDelegate.managedObjectContext) else {return}
            if let _ = book.meta4URL {
                book.isLocal = false
            } else {
                UIApplication.appDelegate.managedObjectContext.deleteObject(book)
            }
        }
    }
    
    private func addNew() {
        for url in zimAdded {
            guard let reader = ZimReader(ZIMFileURL: url) else {continue}
            let id = reader.getID()
            readers[id] = reader
            
            let book: Book? = {
                let book = Book.fetch(id, context: UIApplication.appDelegate.managedObjectContext)
                return book ?? Book.add(reader.metaData, context: UIApplication.appDelegate.managedObjectContext)
            }()
            book?.isLocal = true
            book?.hasIndex = reader.hasIndex()
            book?.hasPic = !reader.fileURL.absoluteString.containsString("nopic")
        }
    }
    
    private var zimFileURLsInDocDir: [NSURL] {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [NSURL]()
        var zimURLs = [NSURL]()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if !isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension.containsString("zim") else {continue}
                        zimURLs.append(url)
                    }
                }
            } catch {
                continue
            }
        }
        return zimURLs
    }
    
    private var indexFolderURLsInDocDir: [NSURL] {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [NSURL]()
        var folderURLs = [NSURL]()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension == "idx" else {continue}
                        folderURLs.append(url)
                    }
                }
            } catch {
                continue
            }
        }
        return folderURLs
    }
}

// This class is unfinished
class RescanZimMultiReaderOperation: Operation {
    override init() {
        super.init()
        addCondition(MutuallyExclusive<ZIMMultiReader>())
    }
    
    override func execute() {
        let context = UIApplication.appDelegate.managedObjectContext
        context.performBlockAndWait { () -> Void in
            // rescan() needs to read from Coredata, ZIMMultiReader use a Main Queue ManagedObjectContext
            ZIMMultiReader.sharedInstance.rescan()
            print("number of readers: \(ZIMMultiReader.sharedInstance.readers.count)")
        }
        finish()
    }
}

extension ZimReader {
    var metaData: [String: AnyObject] {
        var metadata = [String: AnyObject]()
        
        if let id = getID() {metadata["id"] = id}
        if let title = getTitle() {metadata["title"] = title}
        if let description = getDesc() {metadata["description"] = description}
        if let creator = getCreator() {metadata["creator"] = creator}
        if let publisher = getPublisher() {metadata["publisher"] = publisher}
        if let favicon = getFavicon() {metadata["favicon"] = favicon}
        if let date = getDate() {metadata["date"] = date}
        if let articleCount = getArticleCount() {metadata["articleCount"] = articleCount}
        if let mediaCount = getMediaCount() {metadata["mediaCount"] = mediaCount}
        if let fileSize = getFileSize() {metadata["size"] = fileSize}
        if let langCode = getLanguage() {metadata["language"] = langCode}
        
        return metadata
    }
}

class SearchResult {
    let bookID: String
    let title: String
    let percent: Double? // range: 0-100
    let path: String?
    let snippet: String?
    
    init?(rawResult: [String: AnyObject]) {
        self.bookID = (rawResult["bookID"] as? String) ?? ""
        self.title = (rawResult["title"] as? String) ?? ""
        
        self.percent = (rawResult["percent"] as? NSNumber)?.doubleValue
        self.path = rawResult["path"] as? String
        self.snippet = rawResult["snippet"] as? String
        
        if bookID == "" {return nil}
        if title == "" {return nil}
    }
}
