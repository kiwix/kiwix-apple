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
    
    class func add(_ metadata: [String: AnyObject], context: NSManagedObjectContext) -> Book? {
        guard let id = metadata["id"] as? String,
            let book = insert(Book.self, context: context) else {return nil}
        
        book.id = id
        book.title = metadata["title"] as? String
        book.creator = metadata["creator"] as? String
        book.publisher = metadata["publisher"] as? String
        book.desc = metadata["description"] as? String
        book.meta4URL = metadata["url"] as? String
        book.pid = {
            if let pid = metadata["name"] as? String, pid != "" {
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
                return fileSize.int64Value * 1024
            } else {
                return 0
            }
        }()
        
        book.date = {
            guard let date = metadata["date"] as? String else {return nil}
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: date)
        }()
        
        book.favIcon = {
            if let data = metadata["favicon"] as? Data {
                return data
            } else if let favIcon = metadata["favicon"] as? String {
                return Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters)
            } else {
                return nil
            }
        }()
        
        book.hasPic = {
            if let tags = metadata["tags"] as? String, tags.contains("nopic") {
                return false
            } else if let meta4url = book.meta4URL, meta4url.contains("nopic") {
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
    
    var url: URL? {
        guard let meta4URL = meta4URL else {return nil}
        // return url = NSURL(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
        var urlComponents = URLComponents(string: meta4URL.replacingOccurrences(of: ".meta4", with: ""))
        urlComponents?.scheme = "https"
        return urlComponents?.url
    }
    
    // MARK: - Fetch
    
    class func fetchAll(in context: NSManagedObjectContext) -> [Book] {
        let request: NSFetchRequest<Book> = Book.fetchRequest() as! NSFetchRequest<Book>
        return (try? context.fetch(request)) ?? [Book]()
        
//        let request: NSFetchRequest<NSFetchRequestResult> = Book.fetchRequest()
//        let res = try? context.fetch(request)
//        return res
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
//        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
    }
    
    class func fetchLocal(_ context: NSManagedObjectContext) -> [ZimID: Book] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "stateRaw == 2")
        let localBooks = fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
        
        var books = [ZimID: Book]()
        for book in localBooks {
            books[book.id] = book
        }
        return books
    }
    
    class func fetch(_ id: String, context: NSManagedObjectContext) -> Book? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        return fetch(fetchRequest, type: Book.self, context: context)?.first
    }
    
    class func fetch(pid: String, context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
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
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter.string(from: date as Date)
    }
    
    var fileSizeDescription: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var articleCountDescription: String? {
        return articleCountString + (articleCount > 1 ? " articles" : " article")
    }
    
    var articleCountString: String {
        func formattedNumberStringFromDouble(_ num: Double) -> String {
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
        return descriptions.joined(separator: ", ")
    }
    
    var detailedDescription1: String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        return descriptions.joined(separator: "\n")
    }
    
    var detailedDescription2: String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        if let creatorAndPublisherDescription = creatorAndPublisherDescription {descriptions.append(creatorAndPublisherDescription)}
        return descriptions.joined(separator: "\n")
    }
    
    fileprivate var creatorAndPublisherDescription: String? {
        if let creator = self.creator, let publisher = self.publisher {
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
            case 0: return .cloud
            case 1: return .downloading
            case 2: return .local
            case 3: return .retained
            default: return .cloud
            }
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }
    
    var spaceState: BookSpaceState {
        guard let freeSpaceInBytes = UIDevice.availableDiskSpace?.freeSize else {return .enough}
        if (0.8 * Double(freeSpaceInBytes)) > Double(fileSize) {
            return .enough
        } else if freeSpaceInBytes < fileSize{
            return .notEnough
        } else {
            return .caution
        }
    }
}

enum BookState: Int {
    case cloud, downloading, local, retained
}


enum BookSpaceState: Int {
    case enough, caution, notEnough
}
