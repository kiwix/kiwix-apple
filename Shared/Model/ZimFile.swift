//
//  ZimFile.swift
//  iOS
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

class ZimFile: Object {
    @objc dynamic var id = ""
    @objc dynamic var pid: String?
    
    @objc dynamic var title = ""
    @objc dynamic var bookDescription = ""
    @objc dynamic var stateRaw = ""
    @objc dynamic var category = ""
    @objc dynamic var languageCode = ""
    @objc dynamic var remoteURL: String?
    
    @objc dynamic var creationDate = Date()
    
    @objc dynamic var hasPicture = false
    @objc dynamic var hasIndex = false
    @objc dynamic var includeInSearch = true
    
    @objc dynamic var creator = ""
    @objc dynamic var publisher = ""
    
    @objc dynamic var articleCount: Int64 = 0
    @objc dynamic var mediaCount: Int64 = 0
    @objc dynamic var globalCount: Int64 = 0
    @objc dynamic var fileSize: Int64 = 0

    @objc dynamic var icon = Data()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var state: ZimFileState {
        get { return ZimFileState(rawValue:stateRaw) ?? .cloud }
        set { stateRaw = newValue.rawValue }
    }
    
    
//    @NSManaged public var totalBytesWritten: Int64
//    
//    @NSManaged public var articles: Set<Article>
//    @NSManaged public var language: Language?
}

enum ZimFileState: String, CustomStringConvertible {
    case cloud, downloadQueued, downloading, downloadPaused, downloadError, local, retained
    
    var description: String {
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
