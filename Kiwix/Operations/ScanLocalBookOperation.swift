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
    private let context: NSManagedObjectContext
    private(set) var firstBookAdded = false
    private(set) var shouldMigrateBookmarks = false
    
    private(set) var snapshot: URLSnapShot
    private let time = Date()
    
    init(urlSnapshot: URLSnapShot) {
        self.snapshot = urlSnapshot
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = AppDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        super.init()
        add(condition: MutuallyExclusive<ScanLocalBookOperation>())
        name = String(describing: self)
    }
    
    override func execute() {
        defer {finish()}
        
        let newSnapshot = URLSnapShot()
        var addition = newSnapshot - snapshot
        let deletion = snapshot - newSnapshot
        snapshot = newSnapshot
        
        if deletion.indexFolders.count > 0 { addition.zimFiles = newSnapshot.zimFile }
        
        updateReaders(addition: addition.zimFiles, deletion: deletion.zimFiles)
        context.performAndWait {self.updateCoreData()}
        
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
    
    private func updateReaders(addition: Set<URL>, deletion: Set<URL>) {
        print(addition)
        print(deletion)
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
