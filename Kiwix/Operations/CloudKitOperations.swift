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
        super.init(operations: [])
    }
    

}

class FetchBookRecordZoneOperation: Procedure, ResultInjection {
    let database: CKDatabase
    let bookID: String
    var requirement: PendingValue<Void> = .void
    fileprivate(set) var result: PendingValue<CKRecordZone> = .pending
    
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
            if let error = error as? CKError, error.code == .zoneNotFound {
                let zone = CKRecordZone(zoneID: zoneID)
                let modify = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
                modify.database = self.database
                modify.modifyRecordZonesCompletionBlock = { saved, _, error in
                    if let error = error {
                        self.finish(withError: error)
                    } else {
//                        self.result.value = saved?.first
                    }
                }
            } else {
                
            }
        }
        CloudKitQueue.shared.add(operations: fetch)
    }
}
