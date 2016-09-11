//
//  Language+CoreDataProperties.swift
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

extension Language {

    @NSManaged var code: String
    @NSManaged var isDisplayed: Bool
    @NSManaged var name: String?
    
    @NSManaged var books: Set<Book>

}
