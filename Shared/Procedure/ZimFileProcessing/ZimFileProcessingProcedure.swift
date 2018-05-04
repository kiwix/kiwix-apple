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
    func createZimFile(database: Realm, meta: [String: Any]) -> ZimFile {
        let zimFile = ZimFile()
        
        if let id = meta["id"] as? String {
            zimFile.id = id
        }
        
        if let pid = meta["name"] as? String {
            zimFile.pid = pid
        }
        
        if let title = meta["title"] as? String {
            zimFile.title = title
        }
        
        if let description = meta["description"] as? String {
            zimFile.bookDescription = description
        }
        
        if var languageCode = meta["language"] as? String {
            languageCode = Locale.canonicalLanguageIdentifier(from: languageCode)
            zimFile.language = {
                if let language = database.object(ofType: ZimFileLanguage.self, forPrimaryKey: languageCode) {
                    return language
                } else {
                    let language = ZimFileLanguage()
                    language.code = languageCode
                    database.add(language)
                    return language
                }
            }()
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
        }
        
        if let mediaCount = meta["mediaCount"] as? String, let count = Int64(mediaCount) {
            zimFile.mediaCount = count
        }
        if let size = meta["size"] as? String, let fileSize = Int64(size) {
            zimFile.fileSize = fileSize * 1024
        }
        
        if let tags = meta["tags"] as? String {
            zimFile.hasPicture = !tags.contains("nopic")
            zimFile.hasEmbeddedIndex = tags.contains("_ftindex")
        }
        
        if let favIcon = meta["favicon"] as? String, let icon = Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters) {
            zimFile.icon = icon
        }
        
        if let urlString = meta["url"] as? String, var url = URL(string: urlString) {
            if url.lastPathComponent == "meta4" {
                url = url.deletingLastPathComponent()
            }
            zimFile.remoteURL = url.absoluteString
        }
        
        zimFile.category = {
            if let pid = zimFile.pid,
                let categoryRaw = pid.split(separator: ".").last?.split(separator: "_").first {
                return ZimFile.Category(rawValue: String(categoryRaw)) ?? .other
            } else if let categoryRaw = ZimMultiReader.shared.getFileURL(zimFileID: zimFile.id)?.pathComponents.last?.split(separator: "_").first {
                if categoryRaw.contains("stackexchange") {
                    return .stackExchange
                } else {
                    return ZimFile.Category(rawValue: String(categoryRaw)) ?? .other
                }
            } else {
                return .other
            }
        }()
        
        database.add(zimFile)
        return zimFile
    }
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}
