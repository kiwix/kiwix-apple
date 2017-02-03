//
//  UpdateWidgetDataSourceOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/20/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import ProcedureKit
import NotificationCenter

class UpdateWidgetDataSourceOperation: Procedure {
    let context: NSManagedObjectContext
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSOverwriteMergePolicy
        super.init()
        name = String(describing: self)
    }
    
    override func execute() {
        let defaults = UserDefaults(suiteName: "group.kiwix")
        
        var articles = [Article]()
        context.performAndWait { 
            
        }
        
        var bookmarks = [NSDictionary]()
        for article in articles {
            guard let articleData = article.dictionarySerilization() else {continue}
            bookmarks.append(articleData)
        }
        defaults?.set(bookmarks, forKey: "bookmarks")
        NCWidgetController.widgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
        finish()
    }
}
