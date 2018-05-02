//
//  ScanProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import CoreData
import RealmSwift
import ProcedureKit
import SwiftyUserDefaults

class ScanProcedure: Procedure {
    let directories: [URL]
    
    init(directoryURL: URL) {
        self.directories = [directoryURL]
        super.init()
    }
    
    override func execute() {
        updateReaders()
        updateDatabase()
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
        finish()
    }
    
    private func updateReaders() {
        let zimFileURLs = directories.map({ directory -> [URL] in
            let contents = try? FileManager.default
                .contentsOfDirectory(at: directory,
                                     includingPropertiesForKeys: [.isExcludedFromBackupKey],
                                     options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
            return contents ?? []
        }).flatMap({ $0 }).filter({ $0.pathExtension == "zim" || $0.pathExtension == "zimaa" })
        zimFileURLs.forEach({ ZimMultiReader.shared.add(url: $0) })
        ZimMultiReader.shared.removeStaleReaders()
    }
    
    private func updateDatabase() {
        do {
            let zimFileIDs = ZimMultiReader.shared.ids
            let database = try Realm(configuration: Realm.defaultConfig)
            
            try database.write {
                for zimFileID in zimFileIDs {
                    if let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) {
                        // if zim file already exist in database, simply set its state to local
                        zimFile.state = .local
                    } else {
                        // if zim file does not exist in database, create the object
                        var meta = ZimMultiReader.shared.getMetaData(id: zimFileID)
                        clean(meta: &meta)
                        
                        let zimFile = ZimFile(value: meta)
                        zimFile.state = .local
                        zimFile.category = {
                            if let pid = zimFile.pid,
                                let categoryRaw = pid.split(separator: ".").last?.split(separator: "_").first {
                                return ZimFile.Category(rawValue: String(categoryRaw)) ?? .other
                            } else if let categoryRaw = ZimMultiReader.shared.getFileURL(zimFileID: zimFileID)?.pathComponents.last?.split(separator: "_").first {
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
                    }
                }
                
                let localPredicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
                for zimFile in database.objects(ZimFile.self).filter(localPredicate) {
                    guard !zimFileIDs.contains(zimFile.id) else {continue}
                    if let _ = zimFile.remoteURL {
                        zimFile.state = .cloud
                    } else {
                        database.delete(zimFile)
                    }
                }
            }
        } catch {}
    }
    
    private func clean(meta: inout [String: Any]) {
        if let name = meta["name"] as? String, name != "" { meta["pid"] = name }
        
        if let description = meta["description"] as? String { meta["bookDescription"] = description }
        if let language = meta["language"] as? String {
            meta["languageCode"] = Locale.canonicalLanguageIdentifier(from: language)
        }
        if let date = meta["date"] as? String {
            meta["creationDate"] = ScanProcedure.dateFormatter.date(from: date)
        }
        
        if let articleCount = meta["articleCount"] as? NSNumber { meta["articleCount"] = articleCount.int64Value }
        if let mediaCount = meta["mediaCount"] as? NSNumber { meta["mediaCount"] = mediaCount.int64Value }
        if let globalCount = meta["globalCount"] as? NSNumber { meta["globalCount"] = globalCount.int64Value }
        if let fileSize = meta["fileSize"] as? NSNumber { meta["fileSize"] = fileSize.int64Value }
        
        if let tags = meta["tags"] as? String {
            meta["hasPicture"] = !tags.contains("nopic")
            meta["hasEmbeddedIndex"] = tags.contains("_ftindex")
        }
    }
    
    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}

