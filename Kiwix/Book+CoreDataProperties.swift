//
//  Book+CoreDataProperties.swift
//  Kiwix
//
//  Created by Chris Li on 8/11/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Book {

    @NSManaged var articleCount: NSNumber?
    @NSManaged var creator: String?
    @NSManaged var date: NSDate?
    @NSManaged var desc: String?
    @NSManaged var favIcon: NSData?
    @NSManaged var fileName: String?
    @NSManaged var fileSize: NSNumber?
    @NSManaged var globalCount: NSNumber?
    @NSManaged var hasResumeData: NSNumber?
    @NSManaged var idString: String?
    @NSManaged var isLocal: NSNumber?
    @NSManaged var isNoPic: NSNumber?
    @NSManaged var language: String?
    @NSManaged var localURL: String?
    @NSManaged var mediaCount: NSNumber?
    @NSManaged var meta4URL: String?
    @NSManaged var publisher: String?
    @NSManaged var title: String?
    @NSManaged var totalBytesWritten: NSNumber?

}
