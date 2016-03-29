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
    
    private let monitor = DirectoryMonitor(URL: NSFileManager.docDirURL)
    private var zimURLs = Set<NSURL>()
    private var zimAdded = Set<NSURL>()
    private var zimRemoved = Set<NSURL>()
    var readers = [String: ZimReader]()
    
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
        let newZimURLs = Set(NSFileManager.zimFilesInDocDir())
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
        }
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
