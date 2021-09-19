//
//  LibraryScanOperation.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Defaults
import RealmSwift

class LibraryScanOperation: Operation {
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
        closeReadersForDeletedZimFiles()
        
        updateDatabase()
        #if os(iOS)
        LibraryService.shared.applyBackupSetting(isBackupEnabled: Defaults[.backupDocumentDirectory])
        #endif
    }
    
    /// Add readers by scanning the urls specified.
    private func addReadersFromURLs() {
        let zimFileURLs = urls.map({ url -> [URL] in
            if url.hasDirectoryPath {
                let contents = try? FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
                return contents ?? []
            } else {
                return [url]
            }
        }).flatMap({ $0 }).filter({ $0.pathExtension == "zim" })
        zimFileURLs.forEach({ ZimFileService.shared.open(url: $0) })
    }
    
    /// Add readers for all open in place zim files from bookmark data.
    private func addReadersFromBookmarkData() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@ AND openInPlaceURLBookmark != nil",
                                        ZimFile.State.onDevice.rawValue)
            for zimFile in database.objects(ZimFile.self).filter(predicate) {
                var isStale: ObjCBool = false
                guard let bookmarkData = zimFile.openInPlaceURLBookmark,
                    let fileURL = try? NSURL(resolvingBookmarkData: bookmarkData,
                                             options: [],
                                             relativeTo: nil,
                                             bookmarkDataIsStale: &isStale) as URL else {return}
                ZimFileService.shared.open(url: fileURL)
                if isStale.boolValue {
                    try database.write {
                        let bookmarkData = ZimFileService.shared.getFileURLBookmark(zimFileID: zimFile.fileID)
                        zimFile.openInPlaceURLBookmark = bookmarkData
                    }
                }
            }
        } catch {}
    }
    
    /// Close readers for all zim files that are no longer on disk.
    private func closeReadersForDeletedZimFiles() {
        for zimFileID in ZimFileService.shared.zimFileIDs {
            guard let fileURL = ZimFileService.shared.getFileURL(zimFileID: zimFileID),
                  !FileManager.default.fileExists(atPath: fileURL.path) else { continue }
            ZimFileService.shared.close(id: zimFileID)
        }
    }
    
    /// Update on device zim files in the database.
    private func updateDatabase() {
        do {
            let zimFileIDs = ZimFileService.shared.zimFileIDs
            let database = try Realm(configuration: Realm.defaultConfig)
            
            try database.write {
                for zimFileID in zimFileIDs {
                    guard let metadatum = ZimFileService.shared.getMetaData(id: zimFileID) else { continue }
                    let value: [String: Any?] = [
                        "fileID": metadatum.identifier,
                        "groupId": metadatum.groupIdentifier,
                        "title": metadatum.title,
                        "fileDescription": metadatum.fileDescription,
                        "languageCode": metadatum.languageCode,
                        "category": ZimFile.Category(rawValue: metadatum.category) ?? .other,
                        "creator": metadatum.creator,
                        "publisher": metadatum.publisher,
                        "creationDate": metadatum.creationDate,
                        "faviconData": metadatum.faviconData,
                        "size": metadatum.size.int64Value,
                        "articleCount": metadatum.articleCount.int64Value,
                        "mediaCount": metadatum.mediaCount.int64Value,
                        "hasDetails": metadatum.hasDetails,
                        "hasPictures": metadatum.hasPictures,
                        "hasVideos": metadatum.hasVideos,
                        "stateRaw": ZimFile.State.onDevice.rawValue,
                    ]
                    database.create(ZimFile.self, value: value, update: .modified)
                }
                
                // for all zim file objects that are currently onDevice, if the actual file is no longer on disk,
                // set the object's state to remote or delete the object depending on if it can be re-downloaded.
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "stateRaw = %@", ZimFile.State.onDevice.rawValue),
                    NSPredicate(format: "NOT fileID IN %@", Set(zimFileIDs)),
                ])
                for zimFile in database.objects(ZimFile.self).filter(predicate) {
                    if let _ = zimFile.downloadURL {
                        zimFile.state = .remote
                        zimFile.openInPlaceURLBookmark = nil
                    } else {
                        database.delete(zimFile)
                    }
                }
            }
        } catch {}
    }
}
