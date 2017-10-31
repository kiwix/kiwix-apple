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

    // MARK: - Fetch
    
    class func fetchAll(in context: NSManagedObjectContext) -> [Book] {
        let request = Book.fetchRequest() as! NSFetchRequest<Book>
        return (try? context.fetch(request)) ?? [Book]()
    }
    
    class func fetch(states: [BookState], context: NSManagedObjectContext) -> [Book] {
        let request = Book.fetchRequest() as! NSFetchRequest<Book>
        request.predicate = NSPredicate(format: "stateRaw IN %@", states.map({ $0.rawValue }) )
        return (try? context.fetch(request)) ?? [Book]()
    }
    
    class func fetch(id: String, context: NSManagedObjectContext) -> Book? {
        let request = Book.fetchRequest() as! NSFetchRequest<Book>
        request.predicate = NSPredicate(format: "id = %@", id)
        return (try? context.fetch(request))?.first
    }
    
    class func fetch(pid: String, context: NSManagedObjectContext) -> [Book] {
        let request = Book.fetchRequest() as! NSFetchRequest<Book>
        request.predicate = NSPredicate(format: "pid = %@", pid)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? [Book]()
    }
    
    // MARK: - Properties
    
    var url: URL? {
        guard let meta4URL = meta4URL else {return nil}
        var urlComponents = URLComponents(string: meta4URL.replacingOccurrences(of: ".meta4", with: ""))
        urlComponents?.scheme = "https"
        return urlComponents?.url
    }
    
    var state: BookState {
        get { return BookState(rawValue: Int(stateRaw)) ?? .cloud }
        set { stateRaw = Int16(newValue.rawValue) }
    }
    
    @objc var sectionIndex: Int {
        get {
            switch state {
            case .cloud:
                return 0
            case .downloading, .downloadPaused, .downloadQueued, .downloadError:
                return 1
            case .local:
                return 2
            case .retained:
                return 3
            }
        }
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

enum BookState: Int {
    case cloud = 0, downloadQueued, downloading, downloadPaused, downloadError, local, retained
    
    var shortLocalizedDescription: String {
        switch self {
        case .cloud:
            return NSLocalizedString("Cloud", comment: "Book State")
        case .downloadQueued:
            return NSLocalizedString("Queued", comment: "Book State")
        case .downloading:
            return NSLocalizedString("Downloading", comment: "Book State")
        case .downloadPaused:
            return NSLocalizedString("Paused", comment: "Book State")
        case .downloadError:
            return NSLocalizedString("Error", comment: "Book State")
        case .local:
            return NSLocalizedString("Local", comment: "Book State")
        case .retained:
            return NSLocalizedString("Retained", comment: "Book State")
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
    
    case ted
    case vikidia
    case stackExchange
    
    case other
}
