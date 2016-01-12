//
//  Book.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData


class Book: NSManagedObject {

    // MARK: - Add/Update Book
    
    class func add(metadata: [String: AnyObject], context: NSManagedObjectContext) -> Book? {
        guard let book = insert(Book.self, context: context) else {return nil}
        
        book.id = metadata["id"] as? String
        book.title = metadata["title"] as? String
        book.creator = metadata["creator"] as? String
        book.publisher = metadata["publisher"] as? String
        book.desc = metadata["description"] as? String
        book.meta4URL = metadata["url"] as? String
        
        if let articleCount = metadata["articleCount"] as? String, mediaCount = metadata["mediaCount"] as? String, fileSize = metadata["size"] as? String {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            book.articleCount = numberFormatter.numberFromString(articleCount)
            book.mediaCount = numberFormatter.numberFromString(mediaCount)
            
            if let fileSize = numberFormatter.numberFromString(fileSize) {
                book.fileSize = NSNumber(longLong: fileSize.longLongValue * Int64(1024.0))
            }
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
        
        if let languageCode = metadata["language"] as? String {
            if let language = Language.fetchOrAdd(languageCode, context: context) {
                book.language = language
            }
        }

        return book
    }
    
    // MARK: - URL 
    
    var url: NSURL? {
        guard let meta4URL = meta4URL else {return nil}
        return NSURL(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
    }
    
    // MARK: - Fetch
    
    class func fetchAll(context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
    }
    
    class func fetch(id: String, context: NSManagedObjectContext) -> Book? {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        return fetch(fetchRequest, type: Book.self, context: context)?.first
    }
    
    // MARK: - Properties Description
    
    var dateFormatted: String? {
        guard let date = date else {return nil}
        return Utilities.formattedDateStringFromDate(date)
    }
    
    var fileSizeFormatted: String? {
        guard let fileSize = fileSize?.longLongValue else {return nil}
        return Utilities.formattedFileSizeStringFromByteCount(fileSize)
    }
    
    var articleCountFormatted: String? {
        guard let articleCount = articleCount?.longLongValue else {return nil}
        return Utilities.formattedNumberStringFromDouble(Double(articleCount)) + (articleCount >= 1 ? " articles" : " article")
    }
    
    // MARK: - Description Label
    
    var detailedDescription : String? {
        var descriptions = [String]()
        if let dateFormatted = dateFormatted {descriptions.append(dateFormatted)}
        if let fileSizeFormatted = fileSizeFormatted {descriptions.append(fileSizeFormatted)}
        if let articleCountFormatted = articleCountFormatted {descriptions.append(articleCountFormatted)}
        
        guard descriptions.count != 0 else {return nil}
        return descriptions.joinWithSeparator(", ")
    }
    
    private var creatorAndPublisherDescription: String? {
        if let creator = self.creator, publisher = self.publisher {
            if creator == publisher {
                return "Creator and publisher: " + creator
            } else {
                return "Creator: " + creator + " Publisher: " + publisher
            }
        } else if let creator = self.creator {
            return "Creator: " + creator
        } else if let publisher = self.publisher {
            return "Publisher: " + publisher
        } else {
            return nil
        }
    }
    
    var veryDetailedDescription : String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        if let creatorAndPublisherDescription = creatorAndPublisherDescription {descriptions.append(creatorAndPublisherDescription)}
        return descriptions.joinWithSeparator("\n")
    }
    
    // MARK: - States
    
    var spaceState: BookSpaceState {
        guard let fileSize = fileSize?.longLongValue else {return .Enough}
        let freeSpaceInBytes = Utilities.availableDiskspaceInBytes() ?? INT64_MAX
        if (0.8 * Double(freeSpaceInBytes)) > Double(fileSize) {
            return .Enough
        } else if freeSpaceInBytes < fileSize{
            return .NotEnough
        } else {
            return .Caution
        }
    }
}

enum BookSpaceState: Int {
    case Enough, Caution, NotEnough
}
