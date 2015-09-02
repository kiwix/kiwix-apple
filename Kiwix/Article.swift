//
//  Article.swift
//  Kiwix
//
//  Created by Chris Li on 8/19/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import Foundation
import CoreData

@objc(Article)
class Article: NSManagedObject {

    class func article(withUrlString urlString: String, book: Book, context: NSManagedObjectContext) -> Article? {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        fetchRequest.predicate = NSPredicate(format: "urlString = %@ AND belongsToBook = %@", urlString, book)
        
        do {
            let matches = try context.executeFetchRequest(fetchRequest)
            if matches.count == 1 {
                return matches.first as? Article
            } else if matches.count == 0 {
                let article = NSEntityDescription.insertNewObjectForEntityForName("Article", inManagedObjectContext: context) as? Article
                article?.urlString = urlString
                article?.belongsToBook = book
                return article
            } else {
                print ("articleWithTitle url and book: matches.count != 0|1, should never get here")
                return nil
            }
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

}
