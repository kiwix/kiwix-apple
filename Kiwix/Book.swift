//
//  Book.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import Foundation
import CoreData

@objc(Book)
class Book: NSManagedObject {
    
    class func bookWithMetaDataDictionary(metadata: Dictionary<String, String>, context: NSManagedObjectContext) -> Book? {
        if let book = bookWithIDString(metadata["id"]!, context: context) {
            book.title = metadata["title"]
            book.creator = metadata["creator"]
            book.publisher = metadata["publisher"]
            book.language = metadata["language"]
            book.desc = metadata["description"]
            book.meta4URL = metadata["url"]
            book.idString = metadata["id"]
            
            if let articleCount = metadata["articleCount"], mediaCount = metadata["mediaCount"], fileSize = metadata["size"] {
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                book.articleCount = numberFormatter.numberFromString(articleCount)
                book.mediaCount = numberFormatter.numberFromString(mediaCount)
                book.fileSize = numberFormatter.numberFromString(fileSize)
            }
            
            if let date = metadata["date"] {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                book.date = dateFormatter.dateFromString(date)
            }
            
            if let favIcon = metadata["favicon"] {
                book.favIcon = NSData(base64EncodedString: favIcon, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
            }
            
            if let meta4url = book.meta4URL {
                if meta4url.rangeOfString("nopic") != nil {
                    book.isNoPic = true
                } else {
                    book.isNoPic = false
                }
            }
            
            return book
        } else {
            return nil
        }
    }
    
    class func bookWithIDString(idString: String, context: NSManagedObjectContext) -> Book? {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "idString = %@", idString)
        
        do {
            let matches = try context.executeFetchRequest(fetchRequest)
            if matches.count == 1 {
                return matches.first as? Book
            } else if matches.count == 0 {
                return NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: context) as? Book
            } else {
                print ("bookWithIDString, matches.count != 0|1, should never get here")
                return nil
            }
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    class func allOnlineBookIDs(context: NSManagedObjectContext) -> [String] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "downloadState == 0")
        
        do {
            let matches = try context.executeFetchRequest(fetchRequest)
            return (matches as AnyObject).valueForKey("idString") as! [String]
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return [String]()
        }
    }
    
    class func allPausedBooks(context: NSManagedObjectContext) -> [Book]? {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "downloadState == 2")
        
        do {
            let matches = try context.executeFetchRequest(fetchRequest) as? [Book]
            return matches
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    class func formattedArticleCountOf(book: Book) -> String {
        return book.articleCount != nil ? Utilities.formattedNumberStringFromInt(book.articleCount!.intValue) + " articles" : ""
    }
    
    class func formattedDateStringOf(book: Book) -> String {
        return book.date != nil ? Utilities.formattedDateStringFromDate(book.date!) : ""
    }
}
