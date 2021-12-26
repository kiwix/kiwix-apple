//
//  Database.swift
//  Kiwix
//
//  Created by Chris Li on 12/23/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData

class Database {
    static let shared = Database()
    
    private init() {}
    
    /// A persistent container to set up the Core Data stack.
    lazy var persistentContainer: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "DataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }()
}

class Bookmark: NSManagedObject, Identifiable {
    var id: URL { articleURL }
    
    @NSManaged var articleURL: URL
    @NSManaged var thumbImageURL: URL?
    @NSManaged var title: String
    @NSManaged var snippet: String?
    @NSManaged var created: Date
    
    class func fetchRequest() -> NSFetchRequest<Bookmark> {
        super.fetchRequest() as! NSFetchRequest<Bookmark>
    }
}

class ZimFile: NSManagedObject, Identifiable {
    var id: UUID { fileID }
    
    @NSManaged var fileID: UUID
    @NSManaged var name: String
    @NSManaged var mainPage: URL
    @NSManaged var urlBookmark: Data?
    @NSManaged var includedInSearch: Bool
    
    class func fetchRequest() -> NSFetchRequest<ZimFile> {
        super.fetchRequest() as! NSFetchRequest<ZimFile>
    }
}
