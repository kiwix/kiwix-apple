//
//  CoreDataContainer.swift
//  Kiwix
//
//  Created by Chris Li on 11/8/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData

class CoreDataContainer: NSPersistentContainer {
    
    init() {
        let modelURL = Bundle.main.url(forResource: "Kiwix", withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOf: modelURL)
        super.init(name: "kiwix", managedObjectModel: model!)
        loadPersistentStores { (_, _) in }
        viewContext.automaticallyMergesChangesFromParent = true
    }
    
    override class func defaultDirectoryURL() -> URL {
        let urls = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }

}
