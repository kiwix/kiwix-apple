//
//  Article+CoreDataProperties.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Article {

    @NSManaged var isBookmarked: NSNumber?
    @NSManaged var isMainPage: NSNumber?
    @NSManaged var lastPosition: NSNumber?
    @NSManaged var lastReadDate: NSDate?
    @NSManaged var title: String?
    @NSManaged var urlString: String?
    @NSManaged var belongsToBook: Book?

}
