//
//  ScanProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 10/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit
import SwiftyUserDefaults

class ScanProcedure: Procedure {
    let urls: [URL]
    
    init(directoryURL: URL) {
        self.urls = [directoryURL]
        super.init()
    }
    
    override func execute() {
        urls.forEach({ addReader(directoryURL: $0) })
        ZimMultiReader.shared.removeStaleReaders()
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataContainer.shared.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.performAndWait {
            self.updateDatabase(context: context)
        }
        
        print("Scan Finished, number of readers: \(ZimMultiReader.shared.ids.count)")
        finish()
    }
    
    private func addReader(directoryURL: URL) {
        let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isExcludedFromBackupKey],
                                                                options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
        urls?.filter({ $0.pathExtension.contains("zim") }).forEach({ ZimMultiReader.shared.add(url: $0) })
    }
    
    private func updateDatabase(context: NSManagedObjectContext) {
        for id in ZimMultiReader.shared.ids {
            if let book = Book.fetch(id: id, context: context) {
                book.state = .local
            } else {
                guard let meta = ZimMultiReader.shared.getMetaData(id: id) else {return}
                let book = Book(context: context)
                book.id = id
                book.title = meta.title
                book.bookDescription = meta.bookDescription
                book.pid = meta.name
                book.fileSize = meta.fileSize
                book.date = meta.date
                book.creator = meta.creator
                book.publisher = meta.publisher
                book.favIcon = meta.favicon
                book.articleCount = meta.articleCount
                book.mediaCount = meta.mediaCount
                book.globalCount = meta.globalCount
                
                book.language = Language.fetchOrAdd(meta.language, context: context)
                book.state = .local
                
                book.category = {
                    guard let components = ZimMultiReader.shared.getFileURL(zimFileID: id)?.pathComponents,
                        components.indices ~= 2 else {return nil}
                    if let category = BookCategory(rawValue: components[2]) {
                        return category.rawValue
                    } else if components[2] == "stack_exchange" {
                        return BookCategory.stackExchange.rawValue
                    } else {
                        return BookCategory.other.rawValue
                    }
                }()
                
                book.hasPic = {
                    if meta.tags.contains("nopic") {
                        return false
                    } else if let fileName = ZimMultiReader.shared.getFileURL(zimFileID: id)?.pathComponents.last, fileName.contains("nopic") {
                        return false
                    } else {
                        return true
                    }
                }()
                
                book.hasIndex = {
                    if meta.tags.contains("_ftindex") {
                        return true
                    } else {
                        return false
                    }
                }()
            }
        }
        
        for book in Book.fetch(states: [.local], context: context) {
            guard !ZimMultiReader.shared.ids.contains(book.id) else {continue}
            if let _ = book.meta4URL {
                book.state = .cloud
            } else {
                context.delete(book)
            }
        }
        
        guard context.hasChanges else {return}
        try? context.save()
    }
}

