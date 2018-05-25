//
//  ZimFileProcessingProcedure.swift
//  iOS
//
//  Created by Chris Li on 5/3/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift
import ProcedureKit

class ZimFileProcessingProcedure: Procedure {
    func create(database: Realm, id: String, meta: [String: Any]) -> ZimFile {
        let zimFile = ZimFile()
        zimFile.id = id
        update(zimFile: zimFile, meta: meta)
        database.add(zimFile)
        return zimFile
    }
    
    func update(zimFile: ZimFile, meta: [String: Any]) {
        if let pid = meta["name"] as? String {
            zimFile.pid = pid
        }
        
        if let title = meta["title"] as? String {
            zimFile.title = title
        }
        
        if let description = meta["description"] as? String {
            zimFile.bookDescription = description
        }
        
        if let languageCode = meta["language"] as? String {
            zimFile.languageCode = Locale.canonicalLanguageIdentifier(from: languageCode)
        }
        
        if let date = meta["date"] as? String, let creationDate = dateFormatter.date(from: date) {
            zimFile.creationDate = creationDate
        }
        
        if let creator = meta["creator"] as? String {
            zimFile.creator = creator
        }
        
        if let publisher = meta["publisher"] as? String {
            zimFile.publisher = publisher
        }
        
        if let articleCount = meta["articleCount"] as? String, let count = Int64(articleCount) {
            zimFile.articleCount = count
        } else if let articleCount = meta["articleCount"] as? NSNumber {
            zimFile.articleCount = articleCount.int64Value
        }
        
        if let mediaCount = meta["mediaCount"] as? String, let count = Int64(mediaCount) {
            zimFile.mediaCount = count
        } else if let mediaCount = meta["mediaCount"] as? NSNumber {
            zimFile.mediaCount = mediaCount.int64Value
        }
        
        if let size = meta["size"] as? String, let kiloByteCount = Int64(size) {
            zimFile.fileSize = kiloByteCount * 1024
        } else if let byteCount = meta["fileSize"] as? NSNumber {
            zimFile.fileSize = byteCount.int64Value
        }
        
        if let tags = meta["tags"] as? String {
            zimFile.hasPicture = !tags.contains("nopic")
            zimFile.hasEmbeddedIndex = tags.contains("_ftindex")
        }
        
        if let favIcon = meta["favicon"] as? String, let icon = Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters) {
            zimFile.icon = icon
        } else if let icon = meta["icon"] as? Data {
            zimFile.icon = icon
        }
        
        if let urlString = meta["url"] as? String, var url = URL(string: urlString) {
            if url.lastPathComponent == "meta4" {
                url = url.deletingLastPathComponent()
            }
            zimFile.remoteURL = url.absoluteString
        }
        
        zimFile.category = {
            func getFromTags() -> ZimFile.Category? {
                guard let tags = meta["tags"] as? String, let categoryRaw = tags.split(separator: ";").first else {return nil}
                return ZimFile.Category(rawValue: String(categoryRaw))
            }
            func getFromName() -> ZimFile.Category? {
                guard let name = meta["name"] as? String,
                    let categoryRaw = name.split(separator: ".").last?.split(separator: "_").first else {return nil}
                return ZimFile.Category(rawValue: String(categoryRaw))
            }
            func getFromURL() -> ZimFile.Category? {
                guard let urlString = meta["url"] as? String, let url = URL(string: urlString) else {return nil}
                let compoenents = url.pathComponents
                guard compoenents.count > 2 else {return nil}
                let categoryRaw = String(compoenents[2])
                if categoryRaw.contains("stack") && categoryRaw.contains("exchange") {
                    return .stackExchange
                } else {
                    return ZimFile.Category(rawValue: String(categoryRaw))
                }
            }
            func getFromFileName() -> ZimFile.Category? {
                guard let categoryRaw = ZimMultiReader.shared.getFileURL(zimFileID: zimFile.id)?.pathComponents.last?.split(separator: "_").first else {return nil}
                if categoryRaw.contains("stack") && categoryRaw.contains("exchange") {
                    return .stackExchange
                } else {
                    return ZimFile.Category(rawValue: String(categoryRaw))
                }
            }
            return getFromTags() ?? getFromName() ?? getFromURL() ?? getFromFileName() ?? .other
        }()
    }
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}
