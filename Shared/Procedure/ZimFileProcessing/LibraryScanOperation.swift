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
    private let documentDirectoryURL = try! FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    
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
        addReadersFromURLs()
        addReadersFromBookmarkData()
        ZimMultiReader.shared.removeStaleReaders()
        
        updateDatabase()
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
    }
    
    /**
     Add readers by scanning the urls specified.
     */
    private func addReadersFromURLs() {
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
    }
    
    /**
     Add readers for all open in place zim files from bookmark data.
     */
    private func addReadersFromBookmarkData() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@ AND openInPlaceURLBookmark != nil",
                                        ZimFile.State.local.rawValue)
            for zimFile in database.objects(ZimFile.self).filter(predicate) {
                var isStale: ObjCBool = false
                guard let bookmarkData = zimFile.openInPlaceURLBookmark,
                    let fileURL = try? NSURL(resolvingBookmarkData: bookmarkData,
                                             options: [],
                                             relativeTo: nil,
                                             bookmarkDataIsStale: &isStale) as URL else {return}
                ZimMultiReader.shared.add(url: fileURL)
                if isStale.boolValue {
                    try database.write {
                        saveBookmarkData(zimFile: zimFile)
                    }
                }
            }
        } catch {}
    }
    
    private func updateDatabase() {
        do {
            let zimFileIDs = ZimMultiReader.shared.ids
            let database = try Realm(configuration: Realm.defaultConfig)
            
            try database.write {
                for zimFileID in zimFileIDs {
                    let zimFile: ZimFile = {
                        if let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: zimFileID) {
                            // if zim file already exist in database, simply set its state to local
                            return zimFile
                        } else {
                            // if zim file does not exist in database, create the object
                            let meta = ZimMultiReader.shared.getMetaData(id: zimFileID)
                            let zimFile = self.create(database: database, id: zimFileID, meta: meta)
                            return zimFile
                        }
                    }()
                    if zimFile.state != .local { zimFile.state = .local }
                    if zimFile.openInPlaceURLBookmark == nil { saveBookmarkData(zimFile: zimFile) }
                }
                
                // for all zim file objects that are currently local, if the actual file is no longer on disk,
                // set the object's state to cloud or delete the object depending on if it can be re-downloaded.
                let localPredicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.local.rawValue)
                for zimFile in database.objects(ZimFile.self).filter(localPredicate) {
                    guard !zimFileIDs.contains(zimFile.id) else {continue}
                    if let _ = zimFile.remoteURL {
                        zimFile.state = .cloud
                        zimFile.openInPlaceURLBookmark = nil
                    } else {
                        database.delete(zimFile)
                    }
                }
            }
        } catch {}
    }
    
    private func saveBookmarkData(zimFile: ZimFile) {
        guard let fileURL = ZimMultiReader.shared.getFileURL(zimFileID: zimFile.id),
            !zimFile.isInDocumentDirectory else {return}
        zimFile.openInPlaceURLBookmark = try? fileURL.bookmarkData()
    }
}
