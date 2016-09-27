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
    
    class func addOrUpdate(url url: NSURL, context: NSManagedObjectContext) -> Article? {
        guard let bookID = url.host,
            let book = Book.fetch(bookID, context: context),
            let path = url.path else {return nil}
        
        let fetchRequest = NSFetchRequest(entityName: "Article")
        fetchRequest.predicate = NSPredicate(format: "path = %@ AND book = %@", path, book)
        
        guard let article = Article.fetch(fetchRequest, type: Article.self, context: context)?.first ?? insert(Article.self, context: context) else {return nil}
        article.path = path
        article.book = book
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
    
    class func fetchBookmarked(in book: Book, with context: NSManagedObjectContext) -> [Article] {
        let request = NSFetchRequest(entityName: "Article")
        request.predicate = NSPredicate(format: "book = %@", book)
        request.sortDescriptors = [NSSortDescriptor(key: "bookmarkDate", ascending: false)]
        return fetch(request, type: Article.self, context: context) ?? [Article]()
    }
    
    // MARK: - Helper
    
    var url: NSURL? {
        guard let bookID = book?.id else {return nil}
        return NSURL(bookID: bookID, contentPath: path)
    }
    
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
            let bookID = book?.id,
            let url = NSURL(bookID: bookID, contentPath: path) else {return nil}
        return [
            "title": title,
            "thumbImageData": data,
            "url": url.absoluteString!,
            "isMainPage": NSNumber(bool: isMainPage)
        ]
    }
    
}
