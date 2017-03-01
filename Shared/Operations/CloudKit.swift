//
//  CloudKitOperations.swift
//  Kiwix
//
//  Created by Chris Li on 11/27/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CloudKit
import ProcedureKit

class BookmarkSyncOperation: GroupProcedure {
    let articleURL: URL
    
    init(articleURL: URL) {
        self.articleURL = articleURL
        let database = CKContainer(identifier: "iCloud.org.kiwix").privateCloudDatabase
        let zone = FetchBookRecordZoneOperation(database: database, bookID: articleURL.host!)
        let book = FetchBookRecordOperation(database: database, bookID: articleURL.host!)
        book.inject(dependency: zone, block: {book, zone, error in
            book.recordZone = zone.recordZone
        })
        
        super.init(operations: [zone, book])
    }
}

class FetchArticleRecordOperation: Procedure {
    let database: CKDatabase
    let articleURL: URL
    var recordZone: CKRecordZone?
    var bookRecord: CKRecord?
    var articleRecord: CKRecord?
    
    init(database: CKDatabase, articleURL: URL) {
        self.database = database
        self.articleURL = articleURL
        super.init()
    }
    
    override func execute() {
        guard let zone = recordZone, let bookRecord = bookRecord else {
            finish()
            return
        }
        
        let recordID = CKRecordID(recordName: articleURL.absoluteString, zoneID: zone.zoneID)
        let fetch = CKFetchRecordsOperation(recordIDs: [recordID])
        fetch.database = self.database
        fetch.fetchRecordsCompletionBlock = { records, error in
            if let record = records?[recordID] {
//                self.article = record
                
                self.finish()
            } else {
                self.create(recordID: recordID, in: zone)
            }
        }
        CloudKitQueue.shared.add(operations: fetch)
    }
    
    private func create(recordID: CKRecordID, in zone: CKRecordZone) {
        let record = CKRecord(recordType: "Article", recordID: recordID)
        
        let context = AppDelegate.persistentContainer.newBackgroundContext()
    }
    
    private func configure(record: CKRecord, article: Article) {
        
    }
}



class FetchBookRecordOperation: Procedure {
    let database: CKDatabase
    let bookID: String
    var recordZone: CKRecordZone?
    var record: CKRecord?
    
    init(database: CKDatabase, bookID: String) {
        self.database = database
        self.bookID = bookID
        super.init()
    }
    
    override func execute() {
        guard let zone = recordZone else {
            finish()
            return
        }
        
        let recordID = CKRecordID(recordName: self.bookID, zoneID: zone.zoneID)
        let fetch = CKFetchRecordsOperation(recordIDs: [recordID])
        fetch.database = self.database
        fetch.fetchRecordsCompletionBlock = { records, error in
            if let record = records?[recordID] {
                self.record = record
                self.finish()
            } else {
                self.create(recordID: recordID, in: zone)
            }
        }
        CloudKitQueue.shared.add(operations: fetch)
    }
    
    private func create(recordID: CKRecordID, in zone: CKRecordZone) {
        let record = CKRecord(recordType: "Book", recordID: recordID)
        
        let context = AppDelegate.persistentContainer.newBackgroundContext()
        context.performAndWait { 
            guard let book = Book.fetch(self.bookID, context: context) else {return}
            record["id"] = book.id as NSString?
            record["title"] = book.title as NSString?
            record["description"] = book.desc as NSString?
            record["creator"] = book.creator as NSString?
            record["publisher"] = book.publisher as NSString?
            record["favicon"] = book.favIcon as NSData?
            record["date"] = book.date as NSDate?
            record["articleCount"] = book.articleCount as NSNumber
            record["mediaCount"] = book.mediaCount as NSNumber
            record["fileSize"] = book.fileSize as NSNumber
            record["language"] = book.language?.code as NSString?
        }
        
        let modify = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        modify.database = self.database
        modify.modifyRecordsCompletionBlock = { saved, _, error in
            if let record = saved?.first {
                self.record = record
                self.finish()
            } else {
                self.finish(withError: error)
            }
        }
        CloudKitQueue.shared.add(operations: modify)
    }
}

class FetchBookRecordZoneOperation: Procedure {
    let database: CKDatabase
    let bookID: String
    private(set) var recordZone: CKRecordZone?
    
    init(database: CKDatabase, bookID: String) {
        self.database = database
        self.bookID = bookID
        super.init()
    }
    
    override func execute() {
        let zoneID = CKRecordZoneID(zoneName: bookID, ownerName: CKCurrentUserDefaultName)
        let fetch = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
        fetch.database = database
        fetch.fetchRecordZonesCompletionBlock = {zones, error in
            if let error = error as? CKError, (error.code == .partialFailure || error.code == .zoneNotFound) {
                let zone = CKRecordZone(zoneID: zoneID)
                let modify = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
                modify.database = self.database
                modify.modifyRecordZonesCompletionBlock = { saved, _, error in
                    if let zone = saved?.first {
                        self.recordZone = zone
                        self.finish()
                    } else {
                        self.finish(withError: error)
                    }
                }
                CloudKitQueue.shared.add(operations: modify)
            } else if let zone = zones?[zoneID] {
                self.recordZone = zone
                self.finish()
            } else {
                self.finish(withError: error)
            }
        }
        CloudKitQueue.shared.add(operations: fetch)
    }
}
