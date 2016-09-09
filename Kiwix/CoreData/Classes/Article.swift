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
        fetchRequest.predicate = NSPredicate(format: "url = %@", url.absoluteString!)
        let article = Article.fetch(fetchRequest, type: Article.self, context: context)?.first ?? insert(Article.self, context: context)
        
        article?.title = title
        article?.url = url.absoluteString!
        article?.book = book
        
        return article
    }
    
    class func fetchRecentBookmarks(count: Int, context: NSManagedObjectContext) -> [Article] {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        let dateDescriptor = NSSortDescriptor(key: "bookmarkDate", ascending: false)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [dateDescriptor, titleDescriptor]
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == true")
        fetchRequest.fetchLimit = count
        return fetch(fetchRequest, type: Article.self, context: context) ?? [Article]()
    }
    
    // MARK: - Helper
    
    var thumbImageData: NSData? {
        if let urlString = thumbImageURL,
            let url = NSURL(string: urlString),
            let data = NSData(contentsOfURL: url) {
            return data
        } else {
            return book?.favIcon
        }
    }
    
    func dictionarySerilization() -> NSDictionary? {
        guard let title = title,
            let data = thumbImageData,
            let url = NSURL(string: url) else {return nil}
        return [
            "title": title,
            "thumbImageData": data,
            "url": url.absoluteString!,
            "isMainPage": NSNumber(bool: isMainPage)
        ]
    }

}
