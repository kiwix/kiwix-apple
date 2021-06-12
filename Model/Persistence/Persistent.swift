//
//  Persistent.swift
//  Kiwix
//
//  Created by Chris Li on 6/12/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "model")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                // Show some error here
            }
        }
    }
}

class Persistent: NSPersistentContainer {
    static let shared = Persistent()
    
    convenience init() {
        self.init(name: "model")
        loadPersistentStores { description, error in
        }
    }
}
