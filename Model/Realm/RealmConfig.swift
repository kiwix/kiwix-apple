//
//  RealmConfig.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import CoreData
import RealmSwift

extension Realm {
    class ZimFile: Object, ObjectKeyIdentifiable {
        
        // MARK: - nonnull properties
        
        @Persisted(primaryKey: true) var fileID: String = ""
        @Persisted(indexed: true) var groupID: String = ""
        @Persisted(indexed: true) var title: String = ""
        @Persisted(indexed: true) var fileDescription: String = ""
        @Persisted(indexed: true) var languageCode: String = ""
        @Persisted(indexed: true) var creationDate: Date = Date()
        @Persisted(indexed: true) var size: Int64 = 0
        @Persisted(indexed: true) var articleCount: Int64 = 0
        @Persisted(indexed: true) var mediaCount: Int64 = 0
        @Persisted(indexed: true) var categoryRaw: String
        @Persisted(indexed: true) var stateRaw: String
        @Persisted var creator: String = ""
        @Persisted var publisher: String = ""
        
        // MARK: - bool properties
        
        @Persisted var hasDetails = false
        @Persisted var hasIndex = false
        @Persisted var hasPictures = false
        @Persisted var hasVideos = false
        @Persisted var includedInSearch = true
        
        // MARK: - favicon properties
        
        @Persisted var faviconURL: String?
        @Persisted var faviconData: Data?
        
        // MARK: - download properties
        
        @Persisted var downloadURL: String?
        @Persisted var downloadTotalBytesWritten: Int64 = 0
        @Persisted var downloadResumeData: Data?
        @Persisted var downloadErrorDescription: String?
        
        // MARK: - open in place data
        
        @Persisted var openInPlaceURLBookmark: Data?
    }
    
    class Bookmark: Object, ObjectKeyIdentifiable {
        @Persisted var path = ""
        @Persisted var zimFile: ZimFile?
        
        @Persisted var title = ""
        @Persisted var snippet: String?
        @Persisted var thumbImagePath: String?
        @Persisted var date: Date?
    }
    
    static let defaultConfig: Realm.Configuration = {
        // Configure Migrations
        var config = Realm.Configuration(
            schemaVersion: 6,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 4) {
                    migration.renameProperty(onType: ZimFile.className(), from: "id", to: "fileID")
                }
                if (oldSchemaVersion < 5) {
                    migration.enumerateObjects(ofType: ZimFile.className()) { oldObject, newObject in
                        newObject?["creationDate"] = oldObject?["creationDate"] ?? Date()
                        newObject?["size"] = oldObject?["size"] ?? 0
                        newObject?["articleCount"] = oldObject?["articleCount"] ?? 0
                        newObject?["mediaCount"] = oldObject?["mediaCount"] ?? 0
                        newObject?["creator"] = oldObject?["creator"] ?? ""
                        newObject?["publisher"] = oldObject?["publisher"] ?? ""
                    }
                }
            }
        )
        
        // Configure realm database path
        let applicationSupport = try! FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        config.fileURL = applicationSupport.appendingPathComponent("kiwix.realm")
        
        return config
    }()
}

class DatabaseMigration {
    static func migrate() {
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.undoManager = nil
            
            guard let realm = try? Realm() else { return }
            var existingZimFiles = Array(realm.objects(Realm.ZimFile.self))
            do {
                let insertRequest = NSBatchInsertRequest(
                    entity: ZimFile.entity(),
                    managedObjectHandler: { zimFile in
                        guard let zimFile = zimFile as? ZimFile else { return true }
                        while !existingZimFiles.isEmpty {
                            guard let zimFileRealm = existingZimFiles.popLast(),
                                  let zimFileID = UUID(uuidString: zimFileRealm.fileID) else { continue }
                            zimFile.articleCount = zimFileRealm.articleCount
                            zimFile.category = zimFileRealm.categoryRaw
                            zimFile.created = zimFileRealm.creationDate
                            zimFile.fileDescription = zimFileRealm.fileDescription
                            zimFile.fileID = zimFileID
                            zimFile.hasDetails = zimFileRealm.hasDetails
                            zimFile.hasPictures = zimFileRealm.hasPictures
                            zimFile.hasVideos = zimFileRealm.hasVideos
                            zimFile.languageCode = zimFileRealm.languageCode
                            zimFile.mediaCount = zimFileRealm.mediaCount
                            zimFile.name = zimFileRealm.title
                            zimFile.persistentID = zimFileRealm.groupID
                            zimFile.size = zimFileRealm.size
                            
                            if let data = zimFileRealm.openInPlaceURLBookmark {
                                zimFile.fileURLBookmark = data
                            }
                            if let urlString = zimFileRealm.downloadURL, let url = URL(string: urlString) {
                                zimFile.downloadURL = url
                            }
                            if let urlString = zimFileRealm.faviconURL, let url = URL(string: urlString) {
                                zimFile.faviconURL = url
                            }
                            if let data = zimFileRealm.faviconData {
                                zimFile.faviconData = data
                            }
                            return false
                        }
                        return true
                    }
                )
                try context.execute(insertRequest)
            } catch {
                print("ZimFile migration failure: %s", error.localizedDescription)
            }
            
            var existingBookmarks = Array(realm.objects(Realm.Bookmark.self))
            do {
                let insertRequest = NSBatchInsertRequest(
                    entity: Bookmark.entity(),
                    managedObjectHandler: { bookmark in
                        guard let bookmark = bookmark as? Bookmark else { return true }
                        while !existingBookmarks.isEmpty {
                            guard let bookmarkRealm = existingBookmarks.popLast(),
                                  let zimFileID = bookmarkRealm.zimFile?.fileID,
                                  let articleURL = URL(zimFileID: zimFileID, contentPath: bookmarkRealm.path),
                                  let created = bookmarkRealm.date else { continue }
                            bookmark.articleURL = articleURL
                            bookmark.title = bookmarkRealm.title
                            bookmark.snippet = bookmarkRealm.snippet
                            bookmark.created = created
                            if let thumbImagePath = bookmarkRealm.thumbImagePath {
                                bookmark.thumbImageURL = URL(zimFileID: zimFileID, contentPath: thumbImagePath)
                            }
                            return false
                        }
                        return true
                    }
                )
                try context.execute(insertRequest)
            } catch {
                print("Bookmark migration failure: %s", error.localizedDescription)
            }
        }
    }
}
