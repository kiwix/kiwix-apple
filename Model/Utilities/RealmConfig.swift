//
//  RealmConfig.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import CoreData
import RealmSwift
import Realm

private struct ZimFileData {
    let articleCount: Int64
    let category: String
    let created: Date
    let downloadURL: URL?
    let faviconData: Data?
    let faviconURL: URL?
    let fileDescription: String
    let fileID: UUID
    let fileURLBookmark: Data?
    let hasDetails: Bool
    let hasPictures: Bool
    let hasVideos: Bool
    let includedInSearch: Bool
    let languageCode: String
    let mediaCount: Int64
    let name: String
    let persistentID: String
    let size: Int64
}

private struct BookmarkData {
    let zimFileID: UUID
    let articleURL: URL
    let thumbImageURL: URL?
    let title: String
    let snippet: String?
    let created: Date
}

extension Realm {
    static let defaultConfig: Realm.Configuration = {
        // Configure Migrations
        var config = Realm.Configuration(
            schemaVersion: 6,
            migrationBlock: { migration, oldSchemaVersion in
                // get existing zim files
                var existingZimFiles = [ZimFileData]()
                var existingZimFileBookmarks = [Data]()
                migration.enumerateObjects(ofType: "ZimFile") { oldObject, newObject in
                    guard let oldObject = oldObject,
                          let articleCount = oldObject["articleCount"] as? Int64,
                          let category = oldObject["categoryRaw"] as? String,
                          let created = oldObject["creationDate"] as? Date,
                          let fileIDString = oldObject["fileID"] as? String,
                          let fileID = UUID(uuidString: fileIDString),
                          let languageCode = oldObject["languageCode"] as? String,
                          let mediaCount = oldObject["mediaCount"] as? Int64,
                          let name = oldObject["title"] as? String,
                          let persistentID = oldObject["groupID"] as? String,
                          let size = oldObject["size"] as? Int64 else { return }
                    
                    let downloadURL = URL(string: oldObject["downloadURL"] as? String ?? "")
                    let faviconData = oldObject["faviconData"] as? Data
                    let faviconURL = URL(string: oldObject["faviconURL"] as? String ?? "")
                    let fileURLBookmark = oldObject["openInPlaceURLBookmark"] as? Data
                    
                    let zimFileData = ZimFileData(
                        articleCount: articleCount,
                        category: category,
                        created: created,
                        downloadURL: downloadURL,
                        faviconData: faviconData,
                        faviconURL: faviconURL,
                        fileDescription: oldObject["fileDescription"] as? String ?? "",
                        fileID: fileID,
                        fileURLBookmark: fileURLBookmark,
                        hasDetails: oldObject["hasDetails"] as? Bool ?? false,
                        hasPictures: oldObject["hasPictures"] as? Bool ?? false,
                        hasVideos: oldObject["hasVideos"] as? Bool ?? false,
                        includedInSearch: oldObject["includedInSearch"] as? Bool ?? false,
                        languageCode: languageCode,
                        mediaCount: mediaCount,
                        name: name,
                        persistentID: persistentID,
                        size: size
                    )
                    existingZimFiles.append(zimFileData)
                    
                    if let data = fileURLBookmark {
                        existingZimFileBookmarks.append(data)
                    }
                }
                
                // get existing bookmarks
                var existingBookmarks = [BookmarkData]()
                migration.enumerateObjects(ofType: "Bookmark") { oldObject, newObject in
                    guard let oldObject = oldObject,
                          let path = oldObject["path"] as? String,
                          let zimFile = oldObject["zimFile"] as? DynamicObject,
                          let fileIDString = zimFile["fileID"] as? String,
                          let fileID = UUID(uuidString: fileIDString),
                          let articleURL = URL(zimFileID: fileIDString, contentPath: path),
                          let title = oldObject["title"] as? String,
                          let created = oldObject["date"] as? Date else { return }
                    
                    let bookmark = BookmarkData(
                        zimFileID: fileID,
                        articleURL: articleURL,
                        thumbImageURL: {
                            if let thumbImagePath = oldObject["thumbImagePath"] as? String, !thumbImagePath.isEmpty {
                                return URL(zimFileID: fileIDString, contentPath: thumbImagePath)
                            } else {
                                return nil
                            }
                        }(),
                        title: title,
                        snippet: oldObject["snippet"] as? String,
                        created: created
                    )
                    existingBookmarks.append(bookmark)
                }
                
                // migration
                Database.shared.container.performBackgroundTask { context in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    context.undoManager = nil
                    
                    do {
                        // migrate zim files
                        let insertRequest = NSBatchInsertRequest(
                            entity: ZimFile.entity(),
                            managedObjectHandler: { zimFile in
                                guard let zimFile = zimFile as? ZimFile else { return true }
                                while !existingZimFiles.isEmpty {
                                    guard let zimFileData = existingZimFiles.popLast() else { continue }

                                    zimFile.articleCount = zimFileData.articleCount
                                    zimFile.category = (Category(rawValue: zimFileData.category) ?? .other).rawValue
                                    zimFile.created = zimFileData.created
                                    zimFile.downloadURL = zimFileData.downloadURL
                                    zimFile.faviconData = zimFileData.faviconData
                                    zimFile.faviconURL = zimFileData.faviconURL
                                    zimFile.fileDescription = zimFileData.fileDescription
                                    zimFile.fileID = zimFileData.fileID
                                    zimFile.fileURLBookmark = zimFileData.fileURLBookmark
                                    zimFile.hasDetails = zimFileData.hasDetails
                                    zimFile.hasPictures = zimFileData.hasPictures
                                    zimFile.hasVideos = zimFileData.hasVideos
                                    zimFile.includedInSearch = zimFileData.includedInSearch
                                    zimFile.languageCode = zimFileData.languageCode
                                    zimFile.mediaCount = zimFileData.mediaCount
                                    zimFile.name = zimFileData.name
                                    zimFile.persistentID = zimFileData.persistentID
                                    zimFile.size = zimFileData.size

                                    return false
                                }
                                return true
                            }
                        )
                        try context.execute(insertRequest)
                        try context.save()
                        
                        // migrate bookmarks
                        for bookmarkData in existingBookmarks {
                            guard let zimFile = try context.fetch(ZimFile.fetchRequest(fileID: bookmarkData.zimFileID)).first else { return }
                            let bookmark = Bookmark(context: context)
                            bookmark.articleURL = bookmarkData.articleURL
                            bookmark.thumbImageURL = bookmarkData.thumbImageURL
                            bookmark.title = bookmarkData.title
                            bookmark.snippet = bookmarkData.snippet
                            bookmark.created = bookmarkData.created
                            bookmark.zimFile = zimFile
                        }
                        try context.save()
                        
                        // open zim files with bookmark data
                        for data in existingZimFileBookmarks {
                            try ZimFileService.shared.open(bookmark: data)
                        }
                    } catch {
                        print("ZimFile migration failure: %s", error.localizedDescription)
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
    static func start() {
        _ = try? Realm(configuration: Realm.defaultConfig)
    }
}
