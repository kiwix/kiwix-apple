//
//  ZimFile.swift
//  iOS
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

class ZimFile: Object {
    // MARK: -  Properties
    
    @objc dynamic var id = ""
    @objc dynamic var pid: String?
    
    @objc dynamic var title = ""
    @objc dynamic var bookDescription = ""
    @objc dynamic var language: ZimFileLanguage?
    @objc dynamic var creationDate = Date()
    
    @objc dynamic var creator = ""
    @objc dynamic var publisher = ""
    
    @objc dynamic var articleCount: Int64 = 0
    @objc dynamic var mediaCount: Int64 = 0
    @objc dynamic var fileSize: Int64 = 0
    
    @objc dynamic var hasPicture = false
    @objc dynamic var hasEmbeddedIndex = false
    @objc dynamic var includeInSearch = true
    
    @objc dynamic var icon = Data()
    
    @objc dynamic var remoteURL: String?
    
    @objc dynamic var stateRaw = State.cloud.rawValue
    @objc dynamic var categoryRaw = Category.other.rawValue
    
    var state: State {
        get { return State(rawValue:stateRaw) ?? .cloud }
        set { stateRaw = newValue.rawValue }
    }
    
    var category: Category {
        get { return Category(rawValue:stateRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    // MARK: - Overrides
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // MARK: - Descriptions
    
    var creationDateDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter.string(from: creationDate)
    }
    
    var fileSizeDescription: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var articleCountDescription: String {
        return NumberAbbrevationFormatter.string(from: Int(articleCount)) + (articleCount > 1 ? " articles" : " article")
    }
    
    
//    @NSManaged public var totalBytesWritten: Int64
//    
//    @NSManaged public var articles: Set<Article>
//    @NSManaged public var language: Language?
    
    // MARK: - Type Definition
    
    enum State: String {
        case cloud, local, retained
    }
    
    enum Category: String, CustomStringConvertible {
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
        
        var description: String {
            switch self {
            case .wikibooks:
                return NSLocalizedString("Wikibooks", comment: "Zim File Category")
            case .wikinews:
                return NSLocalizedString("Wikinews", comment: "Zim File Category")
            case .wikipedia:
                return NSLocalizedString("Wikipedia", comment: "Zim File Category")
            case .wikiquote:
                return NSLocalizedString("Wikiquote", comment: "Zim File Category")
            case .wikisource:
                return NSLocalizedString("Wikisource", comment: "Zim File Category")
            case .wikispecies:
                return NSLocalizedString("Wikispecies", comment: "Zim File Category")
            case .wikiversity:
                return NSLocalizedString("Wikiversity", comment: "Zim File Category")
            case .wikivoyage:
                return NSLocalizedString("Wikivoyage", comment: "Zim File Category")
            case .wiktionary:
                return NSLocalizedString("Wiktionary", comment: "Zim File Category")
            case .ted:
                return NSLocalizedString("TED", comment: "Zim File Category")
            case .vikidia:
                return NSLocalizedString("Vikidia", comment: "Zim File Category")
            case .stackExchange:
                return NSLocalizedString("StackExchange", comment: "Zim File Category")
            case .other:
                return NSLocalizedString("Other", comment: "Zim File Category")
            }
        }
        
        var icon: UIImage {
            switch self {
            case .wikibooks:
                return #imageLiteral(resourceName: "Wikibooks")
            case .wikinews:
                return #imageLiteral(resourceName: "Wikinews")
            case .wikipedia:
                return #imageLiteral(resourceName: "Wikipedia")
            case .wikiquote:
                return #imageLiteral(resourceName: "Book")
            case .wikisource:
                return #imageLiteral(resourceName: "Book")
            case .wikispecies:
                return #imageLiteral(resourceName: "Wikispecies")
            case .wikiversity:
                return #imageLiteral(resourceName: "Wikiversity")
            case .wikivoyage:
                return #imageLiteral(resourceName: "Wikivoyage")
            case .wiktionary:
                return #imageLiteral(resourceName: "Book")
            case .ted:
                return #imageLiteral(resourceName: "TED")
            case .vikidia:
                return #imageLiteral(resourceName: "Vikidia")
            case .stackExchange:
                return #imageLiteral(resourceName: "StackExchange")
            case .other:
                return #imageLiteral(resourceName: "Book")
            }
        }
    }
    
    class NumberAbbrevationFormatter {
        static func string(from value: Int) -> String {
            let sign = ((value < 0) ? "-" : "" )
            let abs = Swift.abs(value)
            guard abs >= 1000 else {return "\(sign)\(abs)"}
            let exp = Int(log10(Double(abs)) / log10(1000))
            let units = ["K","M","G","T","P","E"]
            let rounded = round(10 * Double(abs) / pow(1000.0,Double(exp))) / 10;
            return "\(sign)\(rounded)\(units[exp-1])"
        }
    }
}
