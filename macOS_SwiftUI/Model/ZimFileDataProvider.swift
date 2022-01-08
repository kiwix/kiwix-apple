//
//  ZimFileDataProvider.swift
//  Kiwix
//
//  Created by Chris Li on 12/28/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData

class ZimFileDataProvider {    
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
