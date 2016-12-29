//
//  Cloud.swift
//  Kiwix
//
//  Created by Chris Li on 12/29/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CloudKit

class Cloud {
    class var privateDatabase: CKDatabase {
        return CKContainer.default().privateCloudDatabase
    }
    
    
    class func subscribeForChanges() {
        let subscription = CKDatabaseSubscription(subscriptionID: "")
        subscription.notificationInfo = CKNotificationInfo()
        subscription.notificationInfo?.shouldSendContentAvailable = true
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.qualityOfService = .utility
        operation.modifySubscriptionsCompletionBlock = { saved, deleted, error in
            if let error = error {
                // handle error
            } else {
                //seuscriptionIsLocallyCached = true
            }
        }
        // add to a database's operation queue
        privateDatabase.add(operation)
        
    }
    
    class func handlePush() {
    
    }
    
}
