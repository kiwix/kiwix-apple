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
        
        let context = Database.shared.container.viewContext
        let zimFile = ZimFile(context: context)
        zimFile.fileID = UUID(uuidString: metadata.identifier)!
        zimFile.name = metadata.title
        zimFile.mainPage = ZimFileService.shared.getMainPageURL(zimFileID: metadata.identifier)!
        zimFile.fileURLBookmark = ZimFileService.shared.getFileURL(zimFileID: metadata.identifier).book
        try? context.save()
    }
    
    class func reopen() {
        let request = ZimFile.fetchRequest(predicate: NSPredicate(format: "fileURLBookmark != nil"))
        let zimFiles = try? Database.shared.container.viewContext.execute(request)
    }
}
