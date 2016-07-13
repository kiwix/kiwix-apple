//
//  ScanLocalBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import PSOperations

class ScanLocalBookOperation: Operation {
    private let context: NSManagedObjectContext
    private var firstBookAdded = false
    
    private var lastZimFileURLSnapshot: Set<NSURL>
    private var currentZimFileURLSnapshot = Set<NSURL>()
    private let lastIndexFolderURLSnapshot: Set<NSURL>
    private var currentIndexFolderURLSnapshot = Set<NSURL>()
    
    private var completionHandler: ((currentZimFileURLSnapshot: Set<NSURL>, currentIndexFolderURLSnapshot: Set<NSURL>, firstBookAdded: Bool) -> Void)
    
    init(lastZimFileURLSnapshot: Set<NSURL>, lastIndexFolderURLSnapshot: Set<NSURL>,
         completionHandler: ((currentZimFileURLSnapshot: Set<NSURL>, currentIndexFolderURLSnapshot: Set<NSURL>, firstBookAdded: Bool) -> Void)) {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSOverwriteMergePolicy
        
        self.lastZimFileURLSnapshot = lastZimFileURLSnapshot
        self.lastIndexFolderURLSnapshot = lastIndexFolderURLSnapshot
        
        self.completionHandler = completionHandler
        super.init()
        addCondition(MutuallyExclusive<ZimMultiReader>())
        name = String(self)
    }
    
    override func execute() {
        defer {finish()}
        
        currentZimFileURLSnapshot = ScanLocalBookOperation.getCurrentZimFileURLsInDocDir()
        currentIndexFolderURLSnapshot = ScanLocalBookOperation.getCurrentIndexFolderURLsInDocDir()
        
        let zimFileHasChanges = lastZimFileURLSnapshot != currentZimFileURLSnapshot
        let indexFolderHasDeletions = lastIndexFolderURLSnapshot.subtract(currentIndexFolderURLSnapshot).count > 0
        
        guard zimFileHasChanges || indexFolderHasDeletions else {return}
        
        if indexFolderHasDeletions {
            lastZimFileURLSnapshot.removeAll()
        }
        
        updateReaders()
        updateCoreData()
    }
    
    override func finished(errors: [NSError]) {
        context.performBlockAndWait {self.context.saveIfNeeded()}
        NSManagedObjectContext.mainQueueContext.performBlockAndWait {NSManagedObjectContext.mainQueueContext.saveIfNeeded()}
        NSOperationQueue.mainQueue().addOperationWithBlock { 
            self.completionHandler(currentZimFileURLSnapshot: self.currentZimFileURLSnapshot,
                currentIndexFolderURLSnapshot: self.currentIndexFolderURLSnapshot, firstBookAdded: self.firstBookAdded)
        }
    }
    
    private func updateReaders() {
        let addedZimFileURLs = currentZimFileURLSnapshot.subtract(lastZimFileURLSnapshot)
        let removedZimFileURLs = lastZimFileURLSnapshot.subtract(currentZimFileURLSnapshot)
        
        guard addedZimFileURLs.count > 0 || removedZimFileURLs.count > 0 else {return}
        ZimMultiReader.sharedInstance.removeReaders(removedZimFileURLs)
        ZimMultiReader.sharedInstance.addReaders(addedZimFileURLs)
    }
    
    private func updateCoreData() {
        let localBooks = Book.fetchLocal(context)
        let zimReaderIDs = Set(ZimMultiReader.sharedInstance.readers.keys)
        let addedZimFileIDs = zimReaderIDs.subtract(Set(localBooks.keys))
        let removedZimFileIDs = Set(localBooks.keys).subtract(zimReaderIDs)
        
        for id in removedZimFileIDs {
            guard let book = localBooks[id] else {continue}
            if let _ = book.meta4URL {
                book.isLocal = false
            } else {
                context.deleteObject(book)
            }
        }
        
        for id in addedZimFileIDs {
            guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
            let book: Book? = {
                let book = Book.fetch(id, context: NSManagedObjectContext.mainQueueContext)
                return book ?? Book.add(reader.metaData, context: NSManagedObjectContext.mainQueueContext)
            }()
            book?.isLocal = true
            book?.hasIndex = reader.hasIndex()
            book?.hasPic = !reader.fileURL.absoluteString.containsString("nopic")
        }
        
        for (id, book) in localBooks {
            guard !context.deletedObjects.contains(book) else {continue}
            guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
            book.hasIndex = reader.hasIndex()
        }
        
        if localBooks.count == 0 && addedZimFileIDs.count == 1 {
            firstBookAdded = true
        }
    }
    
    // MARK: - Helper
    
    private class func getCurrentZimFileURLsInDocDir() -> Set<NSURL> {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [NSURL]()
        var zimURLs = Set<NSURL>()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if !isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension.containsString("zim") else {continue}
                        zimURLs.insert(url)
                    }
                }
            } catch {
                continue
            }
        }
        return zimURLs
    }
    
    private class func getCurrentIndexFolderURLsInDocDir() -> Set<NSURL> {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [NSURL]()
        var folderURLs = Set<NSURL>()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercaseString else {continue}
                        guard pathExtension == "idx" else {continue}
                        folderURLs.insert(url)
                    }
                }
            } catch {
                continue
            }
        }
        return folderURLs
    }

}
