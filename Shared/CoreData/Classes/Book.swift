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
    
    class func fetch(id: String, context: NSManagedObjectContext) -> Book? {
        let fetchRequest = Book.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        return fetch(fetchRequest, type: Book.self, context: context)?.first
    }
    
    class func fetch(pid: String, context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        fetchRequest.predicate = NSPredicate(format: "pid = %@", pid)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return fetch(fetchRequest, type: Book.self, context: context) ?? [Book]()
    }
    
    // MARK: - Properties
    
    var url: URL? {
        guard let meta4URL = meta4URL else {return nil}
        var urlComponents = URLComponents(string: meta4URL.replacingOccurrences(of: ".meta4", with: ""))
        urlComponents?.scheme = "https"
        return urlComponents?.url
    }
    
    // MARK: - Manage
    
    func removeResumeData() {
//        Preference.resumeData[id] = nil
    }
    
    // MARK: - Properties Description
    
    static private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var dateDescription: String? {
        guard let date = date else {return nil}
        return Book.dateFormatter.string(from: date)
    }
    
    var fileSizeDescription: String? {
        guard fileSize != 0 else {return nil}
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var articleCountDescription: String? {
        guard articleCount != 0 else {return nil}
        return BookArticleCountFormatter.string(num: articleCount) + (articleCount > 1 ? " articles" : " article")
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
}

class BookArticleCountFormatter {
    class func string(num: Int64) -> String {
        let sign = ((num < 0) ? "-" : "" )
        let abs = Swift.abs(num)
        guard abs >= 1000 else {return "\(sign)\(abs)"}
        let exp = Int(log10(Double(abs)) / log10(1000))
        let units = ["K","M","G","T","P","E"]
        let rounded = round(10 * Double(abs) / pow(1000.0,Double(exp))) / 10;
        return "\(sign)\(rounded)\(units[exp-1])"
    }
}

enum BookState: Int, CustomStringConvertible {
    case cloud, downloading, local, retained
    
    var description: String {
        switch self {
            case .cloud: return "Cloud"
            case .downloading: return "Downloading"
            case .local: return "Local"
            case .retained: return "Retained"
        }
    }
}

enum BookCategory: String {
    case wikibooks
    case wikinews
    case wikipedia
    case wikiquote
    case wikisource
    case wikispecies
    case wikiversity
    case wikivoyage
    case wiktionary
    
    case gutenberg
    case ted
    case vikidia
    case stackExchange
    
    case other
}
