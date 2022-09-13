//
//  LibraryOperations.swift
//  Kiwix
//
//  Created by Chris Li on 9/12/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import CoreData
import os

struct LibraryOperations {
    private init() {}
    
    // MARK: - Open
    
    /// Open a zim file with url
    /// - Parameter url: url of the zim file
    static func open(url: URL) {
        guard let metadata = ZimFileService.getMetaData(url: url),
              let fileURLBookmark = ZimFileService.getBookmarkData(url: url) else { return }
        // open the file
        do {
            try ZimFileService.shared.open(bookmark: fileURLBookmark)
        } catch {
            return
        }
        
        // upsert zim file in the database
        Database.shared.container.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            let predicate = NSPredicate(format: "fileID == %@", metadata.fileID as CVarArg)
            let fetchRequest = ZimFile.fetchRequest(predicate: predicate)
            guard let zimFile = try? context.fetch(fetchRequest).first ?? ZimFile(context: context) else { return }
            LibraryViewModel.configureZimFile(zimFile, metadata: metadata)
            zimFile.fileURLBookmark = fileURLBookmark
            zimFile.isMissing = false
            if context.hasChanges { try? context.save() }
        }
    }
    
    /// Scan a directory and open available zim files inside it
    /// - Parameter url: directory to scan
    static func scanDirectory(_ url: URL) {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        ).filter({ $0.pathExtension == "zim"}) else { return }
        os_log("Discovered %d probable zim files.", log: Log.LibraryOperations, type: .info, fileURLs.count)
        for fileURL in fileURLs {
            LibraryOperations.open(url: fileURL)
        }
    }
}
