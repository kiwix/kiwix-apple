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
    private let backgroundContext: NSManagedObjectContext
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

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        backgroundQueue.sync { [self] in
            backgroundContext.perform { [self] in
                block(backgroundContext)
            }
        }
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
        #if DEBUG
        print("DB path: \(String(describing: description.url?.absoluteString))")
        #endif

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        return container
    }

    /// Save image data to zim files.
    func saveImageData(url: URL, completion: @escaping (Data) -> Void) {
        URLSession.shared.dataTask(with: url) { [self] data, response, _ in
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let mimeType = response.mimeType,
                  mimeType.contains("image"),
                  let data = data else { return }
            performBackgroundTask { [data] context in
                let predicate = NSPredicate(format: "faviconURL == %@", url as CVarArg)
                let request = ZimFile.fetchRequest(predicate: predicate)
                guard let zimFile = try? context.fetch(request).first else { return }
                zimFile.faviconData = data
                try? context.save()
            }
            completion(data)
        }.resume()
    }
}
