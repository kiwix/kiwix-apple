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
    
    class func bookWithMetaDataDictionary(metadata: [String: AnyObject], context: NSManagedObjectContext) -> Book? {
        if let book = NSEntityDescription.insertNewObjectForEntityForName("Book", inManagedObjectContext: context) as? Book {
            book.idString = metadata["id"] as? String
            book.title = metadata["title"] as? String
            book.creator = metadata["creator"] as? String
            book.publisher = metadata["publisher"] as? String
            book.language = metadata["language"] as? String
            book.desc = metadata["description"] as? String
            book.meta4URL = metadata["url"] as? String
            book.idString = metadata["id"] as? String
            
            if let articleCount = metadata["articleCount"] as? String, mediaCount = metadata["mediaCount"] as? String, fileSize = metadata["size"] as? String {
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                book.articleCount = numberFormatter.numberFromString(articleCount)
                book.mediaCount = numberFormatter.numberFromString(mediaCount)
                book.fileSize = numberFormatter.numberFromString(fileSize)
            }
            
            if let date = metadata["date"] as? String {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                book.date = dateFormatter.dateFromString(date)
            }
            
            if let favIcon = metadata["favicon"] as? NSData {
                book.favIcon = favIcon
            } else if let favIcon = metadata["favicon"] as? String {
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
            } else {
                print ("bookWithIDString, matches.count != 1, there is no such book")
                return nil
            }
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    class func allOnlineBookIDs(context: NSManagedObjectContext) -> [String] {
        if let matches = fetchBook(downloadState: 0, context: context) {
            return (matches as AnyObject).valueForKey("idString") as! [String]
        } else {
            return [String]()
        }
    }
    
    class func allDownloadingBooks(context: NSManagedObjectContext) -> [Book]? {
        return fetchBook(downloadState: 1, context: context)
    }
    
    class func allPausedBooks(context: NSManagedObjectContext) -> [Book]? {
        return fetchBook(downloadState: 2, context: context)
    }
    
    class func allLocalBooks(context: NSManagedObjectContext) -> [String: Book]? {
        if let matches = fetchBook(downloadState: 3, context: context) {
            var localBooks = [String: Book]()
            for book in matches {
                localBooks[book.idString!] = book
            }
            return localBooks
        } else {
            return nil
        }
    }
    
    class func fetchBook(downloadState state: Int16, context: NSManagedObjectContext) -> [Book]? {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "downloadState == \(state)")
        
        do {
            if let matches = try context.executeFetchRequest(fetchRequest) as? [Book] {
                return matches
            }
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        return nil
    }
}

extension Book {
    var dateFormatted: String {
        get {
            return date != nil ? Utilities.formattedDateStringFromDate(date!) : ""
        }
    }
    
    var fileSizeFormatted: String {
        get {
            return fileSize != nil ? Utilities.formattedFileSizeStringFromByteCount(fileSize!.longLongValue * 1024) : ""
        }
    }
    
    var articleCountFormatted: String {
        get {
            if let articleCount = articleCount {
                return Utilities.formattedNumberStringFromInt(articleCount.intValue) + (articleCount.longLongValue <= 1 ? " articles" : " article")
            } else {
                return ""
            }
        }
    }
    
    var detailedDescription : String {
        get {
            return dateFormatted + ", " + fileSizeFormatted + ", " + articleCountFormatted
        }
    }
    
    var veryDetailedDescription : String {
        get {
            var description = self.detailedDescription
            if let desc = desc {
                description = description + "\n" + desc
            }
            
            if let creator = creator, publisher = publisher {
                if creator == publisher {
                    description = description + "\n" + "Creator and publisher: " + creator
                } else {
                    description = description + "\n" + "Creator: " + creator + " Publisher: " + publisher
                }
            } else if let creator = creator {
                description = description + "\n" + "Creator: " + creator
            } else if let publisher = publisher {
                description = description + "\n" + "Publisher: " + publisher
            }
            return description
        }
    }
}
