// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import CoreData
import os

final class Database {
    static let shared = Database()
    private let container: NSPersistentContainer
    let backgroundContext: NSManagedObjectContext
    private let backgroundQueue = DispatchQueue(label: "database.background.queue",
                                                qos: .utility)

    private init() {
        container = Self.createContainer()
        backgroundContext = container.newBackgroundContext()
        backgroundContext.persistentStoreCoordinator = container.persistentStoreCoordinator
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        backgroundContext.undoManager = nil
        backgroundContext.shouldDeleteInaccessibleFaults = true
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// A persistent container to set up the Core Data stack.
    private static func createContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "DataModel")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        if ProcessInfo.processInfo.arguments.contains("testing") {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }
}
