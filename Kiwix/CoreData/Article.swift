//
//  Article.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData


class Article: NSManagedObject {

    class func addOrUpdate(title: String? = nil, url: NSURL, book: Book, context: NSManagedObjectContext) -> Article? {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        fetchRequest.predicate = NSPredicate(format: "urlString = %@", url.absoluteString)
        let article = Article.fetch(fetchRequest, type: Article.self, context: context)?.first ?? insert(Article.self, context: context)
        
        article?.title = title
        article?.urlString = url.absoluteString
        article?.book = book
        
        return article
    }
    
    var url: NSURL? {
        guard let urlString = urlString else {return nil}
        return NSURL(string: urlString)
    }

}
