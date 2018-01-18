//
//  ScanProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit

class ScanProcedure: Procedure {
    let urls: [URL]
    
    init(url: URL) {
        self.urls = [url]
        super.init()
    }
    
    override func execute() {
        urls.forEach({ addReader(dir: $0) })
        ZimMultiReader.shared.removeStaleReaders()
        updateDatabase()
        print("Scan Finished, number of readers: \(ZimMultiReader.shared.ids.count)")
        finish()
    }
    
    func addReader(dir: URL) {
        let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil,
                                                                 options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])) ?? []
        urls.forEach({ ZimMultiReader.shared.add(url: $0) })
    }
    
    func updateDatabase() {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataContainer.shared.viewContext
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.performAndWait {
            for id in ZimMultiReader.shared.ids {
                if let book = Book.fetch(id: id, context: context) {
                    book.state = .local
                } else {
                    guard let meta = ZimMultiReader.shared.getMetaData(id: id) else {return}
                    let book = Book(context: context)
                    book.id = id
                    book.title = meta.title
                    book.bookDescription = meta.bookDescription
                    book.pid = meta.name
                    book.fileSize = meta.fileSize
                    book.date = meta.date
                    book.creator = meta.creator
                    book.publisher = meta.publisher
                    book.favIcon = meta.favicon
                    book.articleCount = meta.articleCount
                    book.mediaCount = meta.mediaCount
                    book.globalCount = meta.globalCount
                    
                    book.language = Language.fetchOrAdd(meta.language, context: context)
                    book.state = .local
                }
            }

            for book in Book.fetch(states: [.local], context: context) {
                guard !ZimMultiReader.shared.ids.contains(book.id) else {continue}
                if let _ = book.meta4URL {
                    book.state = .cloud
                } else {
                    context.delete(book)
                }
            }
            
            context.performAndWait {
                guard context.hasChanges else {return}
                try? context.save()
            }
        }
    }
}

