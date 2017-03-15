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
