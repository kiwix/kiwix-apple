//
//  Book+CoreDataProperties.swift
//  Kiwix
//
//  Created by Chris on 1/10/16.
//  Copyright © 2016 Chris. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Book {

    @NSManaged var articleCount: NSNumber?
    @NSManaged var creator: String?
    @NSManaged var date: NSDate?
    @NSManaged var desc: String?
    @NSManaged var favIcon: NSData?
    @NSManaged var fileSize: NSNumber?
    @NSManaged var globalCount: NSNumber?
    @NSManaged var id: String?
    @NSManaged var isLocal: NSNumber?
    @NSManaged var isNoPic: NSNumber?
    @NSManaged var mediaCount: NSNumber?
    @NSManaged var meta4URL: String?
    @NSManaged var publisher: String?
    @NSManaged var title: String?
    @NSManaged var articles: NSSet?
    @NSManaged var downloadTask: DownloadTask?
    @NSManaged var language: Language?

}
