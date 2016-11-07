//
//  DownloadTask+CoreDataProperties.swift
//  Kiwix
//
//  Created by Chris Li on 3/25/16.
//  Copyright © 2016 Chris. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DownloadTask {

    @NSManaged var creationTime: Date
    @NSManaged var stateRaw: Int16
    @NSManaged var totalBytesWritten: Int64
    @NSManaged var book: Book?

}
