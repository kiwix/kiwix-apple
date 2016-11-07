//
//  BookmarkMigrationOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import CloudKit
import Operations

class BookmarkMigrationOperation: Operation {
    fileprivate let context: NSManagedObjectContext
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        super.init()
        addCondition(MutuallyExclusive<GlobalQueue>())
        name = String(describing: self)
    }
    
    override func execute() {
        context.performAndWait {
            let pids = Book.fetchLocal(self.context).flatMap({$1.pid})
            for pid in pids {
                var books = Book.fetch(pid: pid, context: self.context)
                let latestBook = books.removeFirst()
                for book in books {
                    book.articles.forEach({$0.book = latestBook})
                }
            }
            if self.context.hasChanges {_ = try? self.context.save()}
        }
        finish()
    }
}

class BookmarkTrashOperation: Operation {
    fileprivate let context: NSManagedObjectContext
    fileprivate let articles: [Article]
    
    init(articles: [Article]) {
        self.context = NSManagedObjectContext.mainQueueContext
        self.articles = articles
        
        super.init()
        addCondition(MutuallyExclusive<BookmarkController>())
        name = String(describing: self)
    }
    
    override func execute() {
        context.perform { 
            self.articles.forEach() {
                $0.isBookmarked = false
                $0.bookmarkDate = nil
            }
            
            // Get books whose zim file removed, but are retain by bookmarks, and whose bookmarks are all removed
            let books = Set(self.articles.flatMap({$0.book}))
                .filter({Article.fetchBookmarked(in: $0, with: self.context).count == 0 && $0.state == .retained})
            books.forEach({ (book) in
                if let _ = book.meta4URL {
                    book.state = .cloud
                } else {
                    self.context.delete(book)
                }
            })
            
            if self.context.hasChanges {_ = try? self.context.save()}
        }
        
        if articles.count > 0 {
            produceOperation(UpdateWidgetDataSourceOperation())
        }
        
        finish()
    }
}

class BookmarkCloudKitOperation: Operation {
    let article: Article
    
    init(article: Article) {
        self.article = article
        super.init()
        name = String(describing: self)
    }
    
    override func execute() {
//        guard let bookID = article.book?.id else {finish(); return}
//        let container = CKContainer(identifier: "iCloud.org.kiwix")
//        container.accountStatusWithCompletionHandler { (status, error) in
//            guard status == .Available else {self.finish(); return}
//            
//            container.fetchUserRecordIDWithCompletionHandler({ (recordID, error) in
//                guard let ownerName = recordID?.recordName else {self.finish(); return}
//                let database = container.privateCloudDatabase
//                let zoneID = CKRecordZoneID(zoneName: bookID, ownerName: ownerName)
//                database.fetchRecordZoneWithID(zoneID, completionHandler: { (zone, error) in
//                    if let zone = zone {
//                        
//                    } else {
//                        database.
//                    }
//                })
//            })
//        }
//        
//        
//        
//        guard let bookID = article.book?.id else {finish(); return}
//        
//        let recordID = CKRecordID(recordName: bookID + "|" + article.path)
//        let database = CKContainer(identifier: "iCloud.org.kiwix").privateCloudDatabase
//        
//        database.fetchRecordWithID(recordID) { (record, error) in
//            if let record = record {
//                if self.article.isBookmarked {
//                    self.populate(record, with: self.article)
//                    database.saveRecord(record, completionHandler: { (record, error) in
//                        self.finish()
//                    })
//                } else {
//                    database.deleteRecordWithID(recordID, completionHandler: { (recordID, error) in
//                        self.finish()
//                    })
//                }
//            } else {
//                guard self.article.isBookmarked else {self.finish(); return}
//                let record = CKRecord(recordType: "Article", recordID: recordID)
//                self.populate(record, with: self.article)
//                database.saveRecord(record, completionHandler: { (record, error) in
//                    self.finish()
//                })
//            }
//        }
    }
    
    func populate(_ record: CKRecord, with article: Article) {
        record["path"] = self.article.path as CKRecordValue?
        record["title"] = self.article.title as CKRecordValue?
        record["snippet"] = self.article.snippet as CKRecordValue?
    }
}


