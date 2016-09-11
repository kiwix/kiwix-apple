//
//  Book+CoreDataProperties.swift
//  Kiwix
//
//  Created by Chris Li on 4/12/16.
//  Copyright © 2016 Chris. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Book {

    @NSManaged var articleCount: Int64
    @NSManaged var creator: String?
    @NSManaged var date: NSDate?
    @NSManaged var desc: String?
    @NSManaged var favIcon: NSData?
    @NSManaged var fileSize: Int64
    @NSManaged var globalCount: Int64
    @NSManaged var hasIndex: Bool
    @NSManaged var hasPic: Bool
    @NSManaged var id: String
    @NSManaged var includeInSearch: Bool
    @NSManaged var isLocal: NSNumber?
    @NSManaged var mediaCount: Int64
    @NSManaged var meta4URL: String?
    @NSManaged var pid: String?
    @NSManaged var publisher: String?
    @NSManaged var title: String?
    
    @NSManaged var articles: Set<Article>
    @NSManaged var downloadTask: DownloadTask?
    @NSManaged var language: Language?

}
