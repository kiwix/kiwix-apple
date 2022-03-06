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
    private let urls: [URL]

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
        urls.map { url -> [URL] in
            if url.hasDirectoryPath {
                let contents = try? FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
                )
                return contents ?? []
            } else {
                return [url]
            }
        }
        .flatMap { $0 }
        .filter { $0.pathExtension == "zim" }
        .forEach { ZimFileService.shared.open(url: $0) }
    }
    
    /// Add readers for all open in place zim files from bookmark data.
    private func addReadersFromBookmarkData() {
        do {
            let database = try Realm()
            try database.objects(ZimFile.self).where { zimFile in
                zimFile.stateRaw == ZimFile.State.onDevice.rawValue && zimFile.openInPlaceURLBookmark != nil
            }.forEach { zimFile in
                var isStale: Bool = false
                guard let bookmarkData = zimFile.openInPlaceURLBookmark,
                      let fileURL = try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale) else { return }
                ZimFileService.shared.open(url: fileURL)
                if isStale {
                    try database.write {
                        guard let zimFileID = UUID(uuidString: zimFile.fileID) else { return }
                        let url = ZimFileService.shared.getFileURL(zimFileID: zimFileID)
                        zimFile.openInPlaceURLBookmark = try url?.bookmarkData()
                    }
                }
            }
        } catch {}
    }
    
    /// Close readers for all zim files that are no longer on disk.
    private func closeReadersForDeletedZimFiles() {
        ZimFileService.shared.fileIDs.forEach { zimFileID in
            guard let fileURL = ZimFileService.shared.getFileURL(zimFileID: zimFileID),
                  !FileManager.default.fileExists(atPath: fileURL.path) else { return }
            ZimFileService.shared.close(fileID: zimFileID)
        }
    }
    
    /// Update on device zim files in the database.
    private func updateDatabase() {
        do {
            let zimFileIDs = ZimFileService.shared.fileIDs
            let database = try Realm()
            
            try database.write {
                for zimFileID in zimFileIDs {
                    guard let metadatum = ZimFileService.shared.getMetaData(id: zimFileID) else { continue }
                    let value: [String: Any?] = [
                        "fileID": metadatum.identifier,
                        "groupId": metadatum.groupIdentifier,
                        "title": metadatum.title,
                        "fileDescription": metadatum.fileDescription,
                        "languageCode": metadatum.languageCode,
                        "categoryRaw": (ZimFile.Category(rawValue: metadatum.category) ?? .other).rawValue,
                        "creator": metadatum.creator,
                        "publisher": metadatum.publisher,
                        "creationDate": metadatum.creationDate,
                        "faviconData": ZimFileService.shared.getFavicon(id: metadatum.fileID),
                        "size": metadatum.size.int64Value,
                        "articleCount": metadatum.articleCount.int64Value,
                        "mediaCount": metadatum.mediaCount.int64Value,
                        "hasDetails": metadatum.hasDetails,
                        "hasPictures": metadatum.hasPictures,
                        "hasVideos": metadatum.hasVideos,
                        "stateRaw": ZimFile.State.onDevice.rawValue,
                        "openInPlaceURLBookmark": {
                            guard let fileURL = ZimFileService.shared.getFileURL(zimFileID: zimFileID),
                                  let documentDirectory = try? FileManager.default.url(for: .documentDirectory,in: .userDomainMask, appropriateFor: nil, create: false),
                                  !FileManager.default.fileExists(atPath: documentDirectory.appendingPathComponent(fileURL.lastPathComponent).path) else { return nil }
                            return try? fileURL.bookmarkData()
                        }()
                    ]
                    database.create(ZimFile.self, value: value, update: .modified)
                }
                
                // for all zim file objects that are currently onDevice, if the actual file is no longer on disk,
                // set the object's state to remote or delete the object depending on if it can be re-downloaded.
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "stateRaw = %@", ZimFile.State.onDevice.rawValue),
                    NSPredicate(format: "NOT fileID IN %@", Set(zimFileIDs.map { $0.uuidString.lowercased() })),
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
