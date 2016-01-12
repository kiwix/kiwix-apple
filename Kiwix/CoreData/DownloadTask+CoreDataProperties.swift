//
//  DownloadTask+CoreDataProperties.swift
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

extension DownloadTask {

    @NSManaged var creationTime: NSDate?
    @NSManaged var stateRaw: NSNumber?
    @NSManaged var totalBytesWritten: NSNumber?
    @NSManaged var book: Book?

}
