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
        guard let id = metadata["id"] as? String,
            let book = insert(Book.self, context: context) else {return nil}
        
        book.id = id
        book.title = metadata["title"] as? String
        book.creator = metadata["creator"] as? String
        book.publisher = metadata["publisher"] as? String
        book.desc = metadata["description"] as? String
        book.meta4URL = metadata["url"] as? String
        book.pid = {
            if let pid = metadata["name"] as? String where pid != "" {
                return pid
            } else {
                return nil
            }
        }()
        
        book.articleCount = Int64((metadata["articleCount"] as? String) ?? "") ?? 0
        book.mediaCount = Int64((metadata["mediaCount"] as? String) ?? "") ?? 0
        book.fileSize = {
            if let fileSize = metadata["size"] as? String {
                return (Int64(fileSize) ?? 0) * 1024
            } else if let fileSize = metadata["size"] as? NSNumber {
                return fileSize.longLongValue * 1024
            } else {
                return 0
            }
        }()
        
        book.date = {
            guard let date = metadata["date"] as? String else {return nil}
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.dateFromString(date)
        }()
        
        book.favIcon = {
            if let data = metadata["favicon"] as? NSData {
                return data
            } else if let favIcon = metadata["favicon"] as? String {
                return NSData(base64EncodedString: favIcon, options: .IgnoreUnknownCharacters)
            } else {
                return nil
            }
        }()
        
        book.hasPic = {
            if let tags = metadata["tags"] as? String where tags.containsString("nopic") {
                return false
            } else if let meta4url = book.meta4URL where meta4url.containsString("nopic") {
                return false
            } else {
                return true
            }
        }()
        
        book.language = {
            guard let languageCode = metadata["language"] as? String,
                let language = Language.fetchOrAdd(languageCode, context: context) else {return nil}
            return language
        }()

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
    
    // MARK: - Fetch
    
    class func fetchAll(context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
    }
    
    class func fetchLocal(context: NSManagedObjectContext) -> [ZimID: Book] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "stateRaw == 2")
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
    
    class func fetch(pid pid: String, context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "pid = %@", pid)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
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
    
    // MARK: - Description Label Text
    
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
    
    var state: BookState {
        get {
            switch stateRaw {
            case 0: return .Cloud
            case 1: return .Downloading
            case 2: return .Local
            case 3: return .Retained
            case 4: return .Purgeable
            default: return .Cloud
            }
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }
    
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

enum BookState: Int {
    case Cloud, Downloading, Local, Retained, Purgeable
}


enum BookSpaceState: Int {
    case Enough, Caution, NotEnough
}
