//
//  LibraryScanOperation.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults

class LibraryScanOperation: Operation, ZimFileProcessing {
    let urls: [URL]
    
    init(urls: [URL] = []) {
        self.urls = urls
        super.init()
    }
    
    convenience init(url: URL) {
        self.init(urls: [url])
    }
    
    convenience init(directoryURL: URL) {
        self.init(urls: [directoryURL])
    }
    
    override func main() {
        updateReaders()
        updateDatabase()
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
    }
    
    private func updateReaders() {
        let zimFileURLs = urls.map({ url -> [URL] in
            if url.hasDirectoryPath {
                let contents = try? FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
                return contents ?? []
            } else if url.isFileURL {
                return [url]
            } else {
                return []
            }
        }).flatMap({ $0 }).filter({ $0.pathExtension == "zim" })
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
                        if zimFile.state != .local { zimFile.state = .local }
                    } else {
                        // if zim file does not exist in database, create the object
                        let meta = ZimMultiReader.shared.getMetaData(id: zimFileID)
                        let zimFile = create(database: database, id: zimFileID, meta: meta)
                        zimFile.state = .local
                    }
                }
                
                // for all zim file objects that are currently local, if the actual file is no longer on disk,
                // set the object's state to cloud or delete the object depending on if it can be re-downloaded.
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
}
