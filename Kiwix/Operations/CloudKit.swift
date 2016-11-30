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

//class UpdateArticleOperation: Procedure {
//    let database: CKDatabase
//    let bookID: String
//    
//    init(database: CKDatabase, bookID: String) {
//        self.database = database
//        self.bookID = bookID
//        super.init()
//    }
//    
//    override func execute() {
//        guard let zone = requirement.value else {
//            finish()
//            return
//        }
//        
//        AppDelegate.persistentContainer.performBackgroundTask { (context) in
//            guard let book = Book.fetch(self.bookID, context: context) else {
//                self.finish()
//                return
//            }
//            let fetch = CKFetchRecordsOperation(recordIDs: [bookRecordID])
//            fetch.database = self.database
//            fetch.fetchRecordsCompletionBlock = { records, error in
//                if let book = records?[bookRecordID] {
//                    
//                }
//            }
//        }
//        
//        
//    }
//}

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
        AppDelegate.persistentContainer.performBackgroundTask { (context) in
            let recordID = CKRecordID(recordName: self.bookID, zoneID: zone.zoneID)
            let fetch = CKFetchRecordsOperation(recordIDs: [recordID])
            fetch.database = self.database
            fetch.fetchRecordsCompletionBlock = { records, error in
                if let record = records?[recordID] {
                    self.record = record
                    // update, or not
                    self.finish()
                } else {
                    let record = CKRecord(recordType: "Book", recordID: recordID)
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
            CloudKitQueue.shared.add(operations: fetch)
        }
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
