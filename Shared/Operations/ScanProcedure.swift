//
//  ScanLocalBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit

class ScanLocalBookOperation: Procedure {
    private let context: NSManagedObjectContext
    private(set) var firstBookAdded = false
    private(set) var shouldMigrateBookmarks = false
    
    private(set) var oldSnapshot: URLSnapShot
    private(set) var newSnapshot: URLSnapShot
    private let time = Date()
    
    init(snapshot: URLSnapShot) {
        self.oldSnapshot = snapshot
        self.newSnapshot = snapshot
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = AppDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        super.init()
        add(condition: MutuallyExclusive<ScanLocalBookOperation>())
        name = String(describing: self)
        
        addDidFinishBlockObserver { (procedure, errors) in
            var notification = Notification(name: Notification.Name(rawValue: "LibraryScanFinished"))
            notification.userInfo?["FirstBookAdded"] = self.firstBookAdded
            NotificationCenter.default.post(notification)
        }
    }
    
    override func execute() {
        defer { finish() }
        
        newSnapshot = URLSnapShot()
        if ZimMultiReader.shared.readers.count == 0 {
            // when ZimMultiReader has not reader, only perform addition
            // i.e., when app is launched initialize all zim readers, or when first book is added
            updateReaders(addition: newSnapshot.zimFile)
            context.performAndWait {self.updateCoreData()}
        } else {
            
            var addition = newSnapshot - oldSnapshot
            let deletion = oldSnapshot - newSnapshot
            
            if deletion.indexFolders.count > 0 { addition.zimFiles = newSnapshot.zimFile }
            
            updateReaders(addition: addition.zimFiles, deletion: deletion.zimFiles)
            context.performAndWait {self.updateCoreData()}
        }
        
        let viewContext = AppDelegate.persistentContainer.viewContext
        context.performAndWait { if self.context.hasChanges {try? self.context.save()} }
        viewContext.performAndWait { if viewContext.hasChanges {try? viewContext.save()} }
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        print(String(format: "Scan finshed, lasted for %.4f seconds.", -time.timeIntervalSinceNow))
        if shouldMigrateBookmarks {
//            produce(BookmarkMigrationOperation())
        }
    }
    
    private func updateReaders(addition: Set<URL>, deletion: Set<URL> = Set<URL>()) {
        ZimMultiReader.shared.removeReaders(deletion)
        ZimMultiReader.shared.addReaders(addition)
        ZimMultiReader.shared.producePIDMap()
    }
    
    private func updateCoreData() {
        let localBooks = Book.fetchLocal(in: context).reduce([ZimID: Book]()) { result, book in
            var dict = result
            dict[book.id] = book
            return dict
        }
        let zimReaderIDs = Set(ZimMultiReader.shared.readers.keys)
        let addition = zimReaderIDs.subtracting(Set(localBooks.keys))
        let deletion = Set(localBooks.keys).subtracting(zimReaderIDs)
        
        for id in deletion {
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
        
        for id in addition {
            guard let reader = ZimMultiReader.shared.readers[id],
                let book: Book = {
                    let book = Book.fetch(id, context: AppDelegate.persistentContainer.viewContext)
                    return book ?? Book.add(meta: reader.metaData, in: AppDelegate.persistentContainer.viewContext)
                }() else {return}
            book.state = .local
            book.hasPic = !reader.fileURL.absoluteString.contains("nopic")
            if let downloadTask = book.downloadTask {context.delete(downloadTask)}
        }
        
        if localBooks.count == 0 && addition.count >= 1 {
            firstBookAdded = true
        }
        
        if addition.count >= 1 {
            shouldMigrateBookmarks = true
        }
    }
    
}
