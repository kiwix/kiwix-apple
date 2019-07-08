//
//  LibraryScanOperation.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import RealmSwift
import SwiftyUserDefaults

class LibraryScanOperation: Operation, XMLParserDelegate, ZimFileProcessing {
    let directories: [URL]
    
    init(directoryURL: URL) {
        self.directories = [directoryURL]
        super.init()
    }
    
    override func main() {
        updateReaders()
        updateDatabase()
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
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
                        if zimFile.state != .local { zimFile.state = .local }
                    } else {
                        // if zim file does not exist in database, create the object
                        let meta = ZimMultiReader.shared.getMetaData(id: zimFileID)
                        let zimFile = create(database: database, id: zimFileID, meta: meta)
                        zimFile.state = .local
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
}

