//
//  Article.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import CoreSpotlight

class Article: NSManagedObject {
    
    // MARK: - Fetch
    
    class func fetch(url: URL, context: NSManagedObjectContext) -> Article? {
        guard let bookID = url.host,
            let book = Book.fetch(id: bookID, context: context) else {return nil}
        let path = url.path
        
        let fetchRequest = Article.fetchRequest() as! NSFetchRequest<Article>
        fetchRequest.predicate = NSPredicate(format: "path = %@ AND book = %@", path, book)
        
        guard let article = try? context.fetch(fetchRequest).first ?? Article(context: context) else {return nil}
        article.path = path
        article.book = book
        return article
    }
    
    class func fetchRecentBookmarks(count: Int, context: NSManagedObjectContext) -> [Article] {
        let fetchRequest = Article.fetchRequest() as! NSFetchRequest<Article>
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bookmarkDate", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == true")
        fetchRequest.fetchLimit = count
        return (try? context.fetch(fetchRequest)) ?? [Article]()
    }
    
    class func fetchBookmarked(in book: Book, with context: NSManagedObjectContext) -> [Article] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Article")
        request.predicate = NSPredicate(format: "book = %@ AND isBookmarked == true", book)
        request.sortDescriptors = [NSSortDescriptor(key: "bookmarkDate", ascending: false)]
        return fetch(request, type: Article.self, context: context) ?? [Article]()
    }
    
    // MARK: - CoreSpotlight
    
    var searchableItem: CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet()
        attributeSet.title = title
        attributeSet.contentDescription = snippet
        attributeSet.thumbnailData = thumbImageData
        attributeSet.creator = book?.title
        attributeSet.htmlContentData = htmlContentData
        attributeSet.lastUsedDate = bookmarkDate
        attributeSet.path = path
        return CSSearchableItem(uniqueIdentifier: url?.absoluteString, domainIdentifier: book?.id, attributeSet: attributeSet)
    }
    
    // MARK: - CloudKit
    
//    var cloudKitRecord: CKRecord? {
//        guard let url = url, let bookID = book?.id else {return nil}
//        let recordID = CKRecordID(recordName: url.absoluteString)
//        let bookRecordID = CKRecordID(recordName: bookID)
//        let record = CKRecord(recordType: "Article", recordID: recordID)
//        record["path"] = path as NSString?
//        record["title"] = title as NSString?
//        record["snippet"] = snippet as NSString?
//        record["thumbImagePath"] = thumbImagePath as NSString?
//        record["isBookmarked"] = isBookmarked as NSNumber
//        record["book"] = CKReference(recordID: bookRecordID, action: .deleteSelf)
//        return record
//    }
    
    // MARK: - Properties
    
    var url: URL? {
        guard let bookID = book?.id else {return nil}
        return URL(bookID: bookID, contentPath: path)
    }
    
    var htmlContentData: Data? {
        guard let url = url else {return nil}
        return try? Data(contentsOf: url)
    }
    
    var thumbImageData: Data? {
        if let bookID = book?.id, let path = thumbImagePath,
            let url = URL(bookID: bookID, contentPath: path),
            let data = try? Data(contentsOf: url) {
            return data
        } else {
            return book?.favIcon as Data?
        }
    }
    
}
