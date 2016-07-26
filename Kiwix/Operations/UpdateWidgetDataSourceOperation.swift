//
//  UpdateWidgetDataSourceOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/20/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import PSOperations
import NotificationCenter

class UpdateWidgetDataSourceOperation: Operation {
    let context: NSManagedObjectContext
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.parentContext = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSOverwriteMergePolicy
        super.init()
        name = String(self)
    }
    
    override func execute() {
        let defaults = NSUserDefaults(suiteName: "group.kiwix")
        
        var articles = [Article]()
        context.performBlockAndWait { 
            articles = Article.fetchRecentBookmarks(30, context: self.context)
        }
        
        var bookmarks = [NSDictionary]()
        for article in articles {
            guard let articleData = article.dictionarySerilization() else {continue}
            bookmarks.append(articleData)
        }
        defaults?.setObject(bookmarks, forKey: "bookmarks")
        NCWidgetController.widgetController().setHasContent(bookmarks.count > 0, forWidgetWithBundleIdentifier: "self.Kiwix.Bookmarks")
        finish()
    }
}
