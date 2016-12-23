//
//  Book.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation
import CoreData

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

class Book: NSManagedObject {

    // MARK: - Add
    
    class func add(meta: [String: String], in context: NSManagedObjectContext) -> Book? {
        guard let id = meta["id"] else {return nil}
        let book = Book(context: context)
        
        book.id = id
        book.title = meta["title"]
        book.creator = meta["creator"]
        book.publisher = meta["publisher"]
        book.desc = meta["description"]
        book.meta4URL = meta["url"]
        book.pid = meta["name"]
        
        book.articleCount = {
            guard let string = meta["articleCount"], let value = Int64(string) else {return 0}
            return value
        }()
        book.mediaCount = {
            guard let string = meta["mediaCount"], let value = Int64(string) else {return 0}
            return value
        }()
        book.fileSize = {
            guard let string = meta["size"], let value = Int64(string) else {return 0}
            return value * 1024
        }()
        
        book.date = {
            guard let date = meta["date"] else {return nil}
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: date)
        }()
        
        book.favIcon = {
            guard let favIcon = meta["favicon"] else {return nil}
            return Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters)
        }()
        
        book.hasPic = {
            if let tags = meta["tags"], tags.contains("nopic") {
                return false
            } else if let meta4url = book.meta4URL, meta4url.contains("nopic") {
                return false
            } else {
                return true
            }
        }()
        
        book.language = {
            guard let languageCode = meta["language"],
                let language = Language.fetchOrAdd(languageCode, context: context) else {return nil}
            return language
        }()

        return book
    }
    
    // MARK: - Fetch
    
    class func fetchAll(in context: NSManagedObjectContext) -> [Book] {
        let request = Book.fetchRequest() as! NSFetchRequest<Book>
        return (try? context.fetch(request)) ?? [Book]()
    }
    
    class func fetchLocal(in context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "stateRaw == 2")
        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
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
    
    // MARK: - CloudKit
//    
//    var recordZoneID: CKRecordZoneID {
//        return CKRecordZoneID(zoneName: id, ownerName: CKCurrentUserDefaultName)
//    }
//    
//    var recordID: CKRecordID {
//        return CKRecordID(recordName: id, zoneID: recordZoneID)
//    }
//    
//    var record: CKRecord {
//        let record = CKRecord(recordType: "Book", recordID: recordID)
//        return record
//    }
    
    // MARK: - Properties
    
    var url: URL? {
        guard let meta4URL = meta4URL else {return nil}
        var urlComponents = URLComponents(string: meta4URL.replacingOccurrences(of: ".meta4", with: ""))
        urlComponents?.scheme = "https"
        return urlComponents?.url
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
    
    private var creatorAndPublisherDescription: String? {
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
