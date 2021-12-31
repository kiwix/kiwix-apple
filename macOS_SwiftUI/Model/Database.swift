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
    lazy var container: NSPersistentContainer = {
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
    
    /// Update the local zim file catalog with what's available online.
    func refreshOnlineZimFileCatalog() async throws {
        guard let url = URL(string: "https://library.kiwix.org/catalog/root.xml") else { return }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let parser = OPDSStreamParser()
        try parser.parse(data: data)
        
        do {
            var allZimFileIDs = Set(parser.zimFileIDs)
            let context = container.newBackgroundContext()
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.undoManager = nil  // Set to nil to reduce resource usage, nil by default on iOS/iPadOS
            try await context.perform {
                let request = NSBatchInsertRequest(entity: ZimFile.entity(), managedObjectHandler: { zimFile in
                    guard let zimFile = zimFile as? ZimFile,
                          let id = allZimFileIDs.popFirst(),
                          let metadata = parser.getZimFileMetaData(id: id) else { return true }
                    zimFile.articleCount = metadata.articleCount.int64Value
                    zimFile.category = metadata.category
                    zimFile.created = metadata.creationDate
                    zimFile.faviconData = metadata.faviconData
                    zimFile.faviconURL = metadata.faviconURL
                    zimFile.fileID = metadata.fileID
                    zimFile.languageCode = metadata.languageCode
                    zimFile.mediaCount = metadata.mediaCount.int64Value
                    zimFile.name = metadata.title
                    zimFile.size = metadata.size.int64Value
                    
                    
                    
                    return false
                })
                guard let result = try context.execute(request) as? NSBatchInsertResult,
                      let success = result.result as? Bool,
                      success else { throw OPDSRefreshError.process }
            }
        } catch {
            throw OPDSRefreshError.process
        }
    }
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
    
    @NSManaged var articleCount: Int64
    @NSManaged var category: String
    @NSManaged var created: Date
    @NSManaged var faviconData: Data?
    @NSManaged var faviconURL: URL?
    @NSManaged var fileID: UUID
    @NSManaged var fileURLBookmark: Data?
    @NSManaged var includedInSearch: Bool
    @NSManaged var languageCode: String
    @NSManaged var mediaCount: Int64
    @NSManaged var name: String
    @NSManaged var size: Int64
    
    class func fetchRequest(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = []
    ) -> NSFetchRequest<ZimFile> {
        let request = super.fetchRequest() as! NSFetchRequest<ZimFile>
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
}
