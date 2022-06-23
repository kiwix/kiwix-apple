//
//  Database.swift
//  Kiwix
//
//  Created by Chris Li on 12/23/21.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData

class Database {
    static let shared = Database()
    private var notificationToken: NSObjectProtocol?
    private var token: NSPersistentHistoryToken?
    private var tokenURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("token.data")
    
    private init() {
        notificationToken = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { notification in
                try? self.mergeChanges()
        }
        token = {
            guard let data = UserDefaults.standard.data(forKey: "PersistentHistoryToken") else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }()
    }
    
    deinit {
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    /// A persistent container to set up the Core Data stack.
    lazy var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "DataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
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
    
    /// Create or update a single zim file entry in the local database.
    func upsertZimFile(metadata: ZimFileMetaData, fileURLBookmark: Data?) {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        context.perform {
            let predicate = NSPredicate(format: "fileID == %@", metadata.fileID as CVarArg)
            let fetchRequest = ZimFile.fetchRequest(predicate: predicate)
            guard let zimFile = try? context.fetch(fetchRequest).first ?? ZimFile(context: context) else { return }
            self.configureZimFile(zimFile, metadata: metadata)
            zimFile.fileURLBookmark = fileURLBookmark
            if context.hasChanges { try? context.save() }
        }
    }
    
    /// Save image data to zim files.
    func saveImageData(url: URL, completion: @escaping (Data) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200,
                  let mimeType = response.mimeType,
                  mimeType.contains("image"),
                  let data = data else { return }
            let context = self.container.newBackgroundContext()
            context.perform {
                let predicate = NSPredicate(format: "faviconURL == %@", url as CVarArg)
                let request = ZimFile.fetchRequest(predicate: predicate)
                guard let zimFile = try? context.fetch(request).first else { return }
                zimFile.faviconData = data
                try? context.save()
            }
            completion(data)
        }.resume()
    }
    
    /// Configure a zim file object based on its metadata.
    private func configureZimFile(_ zimFile: ZimFile, metadata: ZimFileMetaData) {
        zimFile.articleCount = metadata.articleCount.int64Value
        zimFile.category = metadata.category
        zimFile.created = metadata.creationDate
        zimFile.fileDescription = metadata.fileDescription
        zimFile.fileID = metadata.fileID
        zimFile.flavor = metadata.flavor
        zimFile.hasDetails = metadata.hasDetails
        zimFile.hasPictures = metadata.hasPictures
        zimFile.hasVideos = metadata.hasVideos
        zimFile.languageCode = metadata.languageCode
        zimFile.mediaCount = metadata.mediaCount.int64Value
        zimFile.name = metadata.title
        zimFile.persistentID = metadata.groupIdentifier
        zimFile.size = metadata.size.int64Value
        
        // Only overwrite favicon data and url if there is a new value
        if let url = metadata.downloadURL { zimFile.downloadURL = url }
        if let url = metadata.faviconURL { zimFile.faviconURL = url }
    }
    
    /// Merge changes performed on batch requests to view context.
    private func mergeChanges() throws {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.undoManager = nil
        context.perform {
            // fetch and merge changes
            let fetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.token)
            guard let result = try? context.execute(fetchRequest) as? NSPersistentHistoryResult,
                  let transactions = result.result as? [NSPersistentHistoryTransaction] else { return }
            self.container.viewContext.perform {
                transactions.forEach { transaction in
                    self.container.viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                    self.token = transaction.token
                }
            }
            
            // update token
            guard let token = transactions.last?.token else { return }
            let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: "PersistentHistoryToken")
            
            // purge history
            let sevenDaysAgo = Date(timeIntervalSinceNow: -3600 * 24 * 7)
            let purgeRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)
            _ = try? context.execute(purgeRequest)
        }
    }
}
