//
//  PersistentContainer.swift
//  Kiwix
//
//  Created by Chris Li on 11/8/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData

class PersistentContainer: NSPersistentContainer {
    static let shared = PersistentContainer()
    
    private init() {
        let modelURL = Bundle.main.url(forResource: "Kiwix", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)
        super.init(name: "kiwix", managedObjectModel: model!)
        
        persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
        persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = false
        
        loadPersistentStores { (_, error) in
            if let error = error {
                print(error)
            }
        }
        viewContext.automaticallyMergesChangesFromParent = true
    }
    
    override class func defaultDirectoryURL() -> URL {
        return try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
    class func saveViewContext() {
        let context = PersistentContainer.shared.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print(error)
            }
        }
    }

}
