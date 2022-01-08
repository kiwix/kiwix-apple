//
//  ZimFileDataProvider.swift
//  Kiwix
//
//  Created by Chris Li on 12/28/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData

class ZimFileDataProvider {
    class func open(url: URL) {
        guard let metadata = ZimFileService.getMetaData(url: url) else { return }
        ZimFileService.shared.open(url: url)
        Task {
            let data = ZimFileService.shared.getFileURLBookmark(zimFileID: metadata.identifier)
            try? await Database.shared.addZimFile(metadata: metadata, fileURLBookmark: data)
        }
//        
//        
//        
//        let context = Database.shared.container.viewContext
//        let zimFile = ZimFile(context: context)
//        zimFile.fileID = UUID(uuidString: metadata.identifier)!
//        zimFile.name = metadata.title
//        zimFile.size = metadata.size.int64Value
//        zimFile.faviconData = metadata.faviconData
//        zimFile.fileURLBookmark = ZimFileService.shared.getFileURLBookmark(zimFileID: metadata.identifier)
//        try? context.save()
    }
    
    class func reopen() {
        let context = Database.shared.container.viewContext
        let request = ZimFile.fetchRequest(predicate: NSPredicate(format: "fileURLBookmark != nil"))
        guard let zimFiles = try? context.fetch(request) else { return }
        zimFiles.forEach { zimFile in
            guard let data = zimFile.fileURLBookmark else { return }
            if let data = ZimFileService.shared.open(bookmark: data) {
                zimFile.fileURLBookmark = data
            }
        }
        if context.hasChanges {
            try? context.save()
        }
    }
}
