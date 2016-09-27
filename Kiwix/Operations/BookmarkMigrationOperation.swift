//
//  BookmarkMigrationOperation.swift
//  Kiwix
//
//  Created by Chris Li on 9/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import Operations

class BookmarkMigrationOperation: Operation {
    private let context: NSManagedObjectContext
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        super.init()
        addCondition(MutuallyExclusive<GlobalQueue>())
        name = String(self)
    }
    
    override func execute() {
        context.performBlockAndWait {
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
    }
}
