//
//  ScanLocalBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import ProcedureKit

class ScanLocalBookOperation: Procedure {
    fileprivate let context: NSManagedObjectContext
    fileprivate(set) var firstBookAdded = false
    fileprivate(set) var shouldMigrateBookmarks = false
    
    fileprivate var lastZimFileURLSnapshot: Set<URL>
    fileprivate(set) var currentZimFileURLSnapshot = Set<URL>()
    fileprivate let lastIndexFolderURLSnapshot: Set<URL>
    fileprivate(set) var currentIndexFolderURLSnapshot = Set<URL>()
    
    fileprivate let time = Date()
    
    init(lastZimFileURLSnapshot: Set<URL>, lastIndexFolderURLSnapshot: Set<URL>) {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.lastZimFileURLSnapshot = lastZimFileURLSnapshot
        self.lastIndexFolderURLSnapshot = lastIndexFolderURLSnapshot
        
        super.init()
        add(MutuallyExclusive<ZimMultiReader>())
        name = String(describing: self)
    }
    
    override func execute() {
        defer {finish()}
        
        currentZimFileURLSnapshot = getCurrentZimFileURLsInDocDir()
        currentIndexFolderURLSnapshot = getCurrentIndexFolderURLsInDocDir()
        
        let indexFolderHasDeletions = lastIndexFolderURLSnapshot.subtracting(currentIndexFolderURLSnapshot).count > 0
        
        if indexFolderHasDeletions {
            lastZimFileURLSnapshot.removeAll()
        }
        
        updateReaders()
        context.performAndWait {self.updateCoreData()}
        
        context.performAndWait {self.context.saveIfNeeded()}
        NSManagedObjectContext.mainQueueContext.performAndWait {NSManagedObjectContext.mainQueueContext.saveIfNeeded()}
    }
    
    override func operationDidFinish(_ errors: [Error]) {
        print(String(format: "Scan finshed, lasted for %.4f seconds.", -time.timeIntervalSinceNow))
        if shouldMigrateBookmarks {
            produce(BookmarkMigrationOperation())
        }
    }
    
    fileprivate func updateReaders() {
        let addedZimFileURLs = currentZimFileURLSnapshot.subtracting(lastZimFileURLSnapshot)
        let removedZimFileURLs = lastZimFileURLSnapshot.subtracting(currentZimFileURLSnapshot)
        
        ZimMultiReader.shared.removeReaders(removedZimFileURLs)
        ZimMultiReader.shared.addReaders(addedZimFileURLs)
        ZimMultiReader.shared.producePIDMap()
    }
    
    fileprivate func updateCoreData() {
        let localBooks = Book.fetchLocal(context)
        let zimReaderIDs = Set(ZimMultiReader.shared.readers.keys)
        let addedZimFileIDs = zimReaderIDs.subtracting(Set(localBooks.keys))
        let removedZimFileIDs = Set(localBooks.keys).subtracting(zimReaderIDs)
        
        for id in removedZimFileIDs {
            guard let book = localBooks[id] else {continue}
            if book.articles.filter({ $0.isBookmarked }).count > 0 {
                book.state = .retained
            } else {
                if let _ = book.meta4URL {
                    book.state = .cloud
                } else {
                    context.delete(book)
                }
            }
        }
        
        for id in addedZimFileIDs {
            guard let reader = ZimMultiReader.shared.readers[id],
                let book: Book = {
                    let book = Book.fetch(id, context: NSManagedObjectContext.mainQueueContext)
                    return book ?? Book.add(reader.metaData, context: NSManagedObjectContext.mainQueueContext)
                }() else {return}
            book.state = .local
            book.hasPic = !reader.fileURL.absoluteString!.contains("nopic")
            if let downloadTask = book.downloadTask {context.delete(downloadTask)}
        }
        
        if localBooks.count == 0 && addedZimFileIDs.count >= 1 {
            firstBookAdded = true
        }
        
        if addedZimFileIDs.count >= 1 {
            shouldMigrateBookmarks = true
        }
    }
    
    // MARK: - Helper
    
    fileprivate func getCurrentZimFileURLsInDocDir() -> Set<URL> {
        var urls = FileManager.getContents(dir: FileManager.docDirURL)
        let keys = [URLResourceKey.isDirectoryKey]
        urls = urls.filter { (url) -> Bool in
            guard let values = try? (url as NSURL).resourceValues(forKeys: keys),
                let isDirectory = (values[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue, isDirectory == false else {return false}
            guard let pathExtension = url.pathExtension?.lowercased(), pathExtension.contains("zim") else {return false}
            return true
        }
        return Set(urls)
    }
    
    fileprivate func getCurrentIndexFolderURLsInDocDir() -> Set<URL> {
        var urls = FileManager.getContents(dir: FileManager.docDirURL)
        let keys = [URLResourceKey.isDirectoryKey]
        urls = urls.filter { (url) -> Bool in
            guard let values = try? (url as NSURL).resourceValues(forKeys: keys),
                let isDirectory = (values[URLResourceKey.isDirectoryKey] as? NSNumber)?.boolValue, isDirectory == true else {return false}
            guard let pathExtension = url.pathExtension?.lowercased(), pathExtension == "idx" else {return false}
            return true
        }
        return Set(urls)
    }

}
