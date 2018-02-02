//
//  Article+CoreDataProperties.swift
//  Kiwix
//
//  Created by Chris on 1/10/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Article {
    @NSManaged var bookmarkDate: Date?
    @NSManaged var isBookmarked: Bool
    @NSManaged var isMainPage: Bool
    @NSManaged var lastPosition: NSNumber?
    @NSManaged var lastReadDate: Date?
    @NSManaged var path: String
    @NSManaged var snippet: String?
    @NSManaged var title: String?
    
    @NSManaged var book: Book?
    @NSManaged var tags: NSSet?
    @NSManaged var thumbImagePath: String?
}

extension Book {
    @NSManaged public var articleCount: Int64
    @NSManaged public var bookDescription: String?
    @NSManaged public var category: String?
    @NSManaged public var creator: String?
    @NSManaged public var date: Date?
    @NSManaged public var favIcon: Data?
    @NSManaged public var fileSize: Int64
    @NSManaged public var globalCount: Int64
    @NSManaged public var hasPic: Bool
    @NSManaged public var id: String
    @NSManaged public var includeInSearch: Bool
    @NSManaged public var mediaCount: Int64
    @NSManaged public var meta4URL: String?
    @NSManaged public var pid: String?
    @NSManaged public var publisher: String?
    @NSManaged public var stateRaw: Int16
    @NSManaged public var title: String?
    @NSManaged public var totalBytesWritten: Int64
    
    @NSManaged public var articles: Set<Article>
    @NSManaged public var language: Language?
}

extension Language {
    @NSManaged var code: String
    @NSManaged var isDisplayed: Bool
    @NSManaged var name: String?
    
    @NSManaged var books: Set<Book>
}
