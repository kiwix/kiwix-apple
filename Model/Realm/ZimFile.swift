//
//  ZimFile.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif
import RealmSwift

class ZimFile: Object, ObjectKeyIdentifiable {
    
    // MARK: - nonnull properties
    
    @Persisted(primaryKey: true) var fileID: String = ""
    @Persisted(indexed: true) var groupID: String = ""
    @Persisted(indexed: true) var title: String = ""
    @Persisted(indexed: true) var fileDescription: String = ""
    @Persisted(indexed: true) var languageCode: String = ""
    @Persisted(indexed: true) var creationDate: Date = Date()
    @Persisted(indexed: true) var size: Int64 = 0
    @Persisted var articleCount: Int64 = 0
    @Persisted var mediaCount: Int64 = 0
    @Persisted var creator: String = ""
    @Persisted var publisher: String = ""
    @Persisted var categoryRaw: String = Category.other.rawValue
    @Persisted var stateRaw: String = State.remote.rawValue
    
    // MARK: - bool properties
    
    @Persisted var hasDetails = false
    @Persisted var hasIndex = false
    @Persisted var hasPictures = false
    @Persisted var hasVideos = false
    @Persisted var includedInSearch = true
    
    // MARK: - favicon properties
    
    @Persisted var faviconURL: String?
    @Persisted var faviconData: Data?
    
    // MARK: - download properties
    
    @Persisted var downloadURL: String?
    @Persisted var downloadTotalBytesWritten: Int64 = 0
    @Persisted var downloadResumeData: Data?
    @Persisted var downloadErrorDescription: String?
    
    // MARK: - open in place data
    
    @Persisted var openInPlaceURLBookmark: Data?
    
    // MARK: -  computed properties
    
    var state: State {
        get { State(rawValue: stateRaw) ?? .remote }
        set { stateRaw = newValue.rawValue }
    }
    
    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    // MARK: - Overrides
    
    override static func primaryKey() -> String? {
        "fileID"
    }
    
    override static func indexedProperties() -> [String] {
        ["name", "title", "languageCode", "categoryRaw", "creationDate", "stateRaw", "includedInSearch", "faviconURL"]
    }
    
    // MARK: - Descriptions
    
    override var description: String {
        [self.sizeDescription, self.creationDateDescription, NumberAbbrevationFormatter.string(from: articleCount)]
            .joined(separator: ", ")
    }
    
    var creationDateDescription: String {
        ZimFile.dateFormatter.string(from: creationDate)
    }
    
    var sizeDescription: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    // MARK: - Formatters
    
    static private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Type Definition
    
    enum State: String {
        case remote, onDevice, retained, downloadQueued, downloadInProgress, downloadPaused, downloadError
    }
    
    enum Category: String, CaseIterable, CustomStringConvertible, Identifiable {
        case wikipedia
        case wikibooks
        case wikinews
        case wikiquote
        case wikisource
        case wikiversity
        case wikivoyage
        case wiktionary
        
        case ted
        case vikidia
        case stackExchange = "stack_exchange"
        case other
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .wikipedia:
                return NSLocalizedString("Wikipedia", comment: "Zim File Category")
            case .wikibooks:
                return NSLocalizedString("Wikibooks", comment: "Zim File Category")
            case .wikinews:
                return NSLocalizedString("Wikinews", comment: "Zim File Category")
            case .wikiquote:
                return NSLocalizedString("Wikiquote", comment: "Zim File Category")
            case .wikisource:
                return NSLocalizedString("Wikisource", comment: "Zim File Category")
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
                return #imageLiteral(resourceName: "Wikiquote")
            case .wikisource:
                return #imageLiteral(resourceName: "Wikisource")
            case .wikiversity:
                return #imageLiteral(resourceName: "Wikiversity")
            case .wikivoyage:
                return #imageLiteral(resourceName: "Wikivoyage")
            case .wiktionary:
                return #imageLiteral(resourceName: "Wiktionary")
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
        static func string(from value: Int64) -> String {
            let sign = ((value < 0) ? "-" : "" )
            let abs = Swift.abs(value)
            guard abs >= 1000 else {return "\(sign)\(abs)"}
            let exp = Int(log10(Double(abs)) / log10(1000))
            let units = ["K", "M", "G", "T", "P", "E"]
            let rounded = round(10 * Double(abs) / pow(1000.0,Double(exp))) / 10;
            return "\(sign)\(rounded)\(units[exp-1])"
        }
    }
}
