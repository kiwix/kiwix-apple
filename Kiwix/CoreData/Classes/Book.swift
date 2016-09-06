//
//  Book.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData
#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

class Book: NSManagedObject {

    // MARK: - Add Book
    
    class func add(metadata: [String: AnyObject], context: NSManagedObjectContext) -> Book? {
        guard let id = metadata["id"] as? String else {return nil}
        guard let book = insert(Book.self, context: context) else {return nil}
        
        book.id = id
        book.title = metadata["title"] as? String
        book.creator = metadata["creator"] as? String
        book.publisher = metadata["publisher"] as? String
        book.desc = metadata["description"] as? String
        book.meta4URL = metadata["url"] as? String
        
        if let articleCount = metadata["articleCount"] as? String, mediaCount = metadata["mediaCount"] as? String, fileSize = metadata["size"] as? String {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            book.articleCount = numberFormatter.numberFromString(articleCount)?.longLongValue ?? 0
            book.mediaCount = numberFormatter.numberFromString(mediaCount)?.longLongValue ?? 0
            
            if let fileSize = numberFormatter.numberFromString(fileSize) {
                book.fileSize = NSNumber(longLong: fileSize.longLongValue * Int64(1024.0)).longLongValue
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
            book.favIcon = NSData(base64EncodedString: favIcon, options: .IgnoreUnknownCharacters)
        }
        
        if let meta4url = book.meta4URL {
            book.hasPic = !meta4url.containsString("nopic")
        }
        
        if let languageCode = metadata["language"] as? String {
            if let language = Language.fetchOrAdd(languageCode, context: context) {
                book.language = language
            }
        }

        return book
    }
    
    // MARK: - Properties
    
    var url: NSURL? {
        guard let meta4URL = meta4URL else {return nil}
        // return url = NSURL(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
        let urlComponents = NSURLComponents(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
        urlComponents?.scheme = "https"
        return urlComponents?.URL
    }
    
    var resumeDataURL: NSURL? {
        guard let folderURL = NSURL(fileURLWithPath: NSFileManager.libDirURL.path!).URLByAppendingPathComponent("DownloadTemp", isDirectory: true),
            let folderPath = folderURL.path else {return nil}
        if !NSFileManager.defaultManager().fileExistsAtPath(folderPath) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtURL(folderURL, withIntermediateDirectories: true, attributes: [NSURLIsExcludedFromBackupKey: true])
        }
        return folderURL.URLByAppendingPathComponent(id)
    }
    
    // MARK: - Fetch
    
    class func fetchAll(context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
    }
    
    class func fetchLocal(context: NSManagedObjectContext) -> [ZimID: Book] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let predicate = NSPredicate(format: "isLocal = true")
        fetchRequest.predicate = predicate
        let localBooks = fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
        
        var books = [ZimID: Book]()
        for book in localBooks {
            books[book.id] = book
        }
        return books
    }
    
    class func fetch(id: String, context: NSManagedObjectContext) -> Book? {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        return fetch(fetchRequest, type: Book.self, context: context)?.first
    }
    
    // MARK: - Manage
    
    func removeResumeData() {
        Preference.resumeData[id] = nil
    }
    
    // MARK: - Properties Description
    
    var dateDescription: String? {
        guard let date = date else {return nil}
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .MediumStyle
        return formatter.stringFromDate(date)
    }
    
    var fileSizeDescription: String {
        return NSByteCountFormatter.stringFromByteCount(fileSize, countStyle: .File)
    }
    
    var articleCountDescription: String? {
        return articleCountString + (articleCount > 1 ? " articles" : " article")
    }
    
    var articleCountString: String {
        func formattedNumberStringFromDouble(num: Double) -> String {
            let sign = ((num < 0) ? "-" : "" )
            let abs = fabs(num)
            guard abs >= 1000.0 else {
                if abs - Double(Int(abs)) == 0 {
                    return "\(sign)\(Int(abs))"
                } else {
                    return "\(sign)\(abs)"
                }
            }
            let exp: Int = Int(log10(abs) / log10(1000))
            let units: [String] = ["K","M","G","T","P","E"]
            let roundedNum: Double = round(10 * abs / pow(1000.0,Double(exp))) / 10;
            return "\(sign)\(roundedNum)\(units[exp-1])"
        }
        return formattedNumberStringFromDouble(Double(articleCount))
    }
    
    // MARK: - Description Label
    
    var detailedDescription: String? {
        var descriptions = [String]()
        if let dateDescription = dateDescription {descriptions.append(dateDescription)}
        descriptions.append(fileSizeDescription)
        if let articleCountDescription = articleCountDescription {descriptions.append(articleCountDescription)}
        
        guard descriptions.count != 0 else {return nil}
        return descriptions.joinWithSeparator(", ")
    }
    
    var detailedDescription1: String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        return descriptions.joinWithSeparator("\n")
    }
    
    var detailedDescription2: String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        if let creatorAndPublisherDescription = creatorAndPublisherDescription {descriptions.append(creatorAndPublisherDescription)}
        return descriptions.joinWithSeparator("\n")
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
    
    // MARK: - States
    
    var spaceState: BookSpaceState {
        guard let freeSpaceInBytes = UIDevice.availableDiskSpace?.freeSize else {return .Enough}
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
