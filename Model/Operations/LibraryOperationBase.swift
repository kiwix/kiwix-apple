//
//  LibraryOperationBase.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

class LibraryOperationQueue: OperationQueue {
    static let shared = LibraryOperationQueue()
    private(set) weak var currentOPDSRefreshOperation: OPDSRefreshOperation?

    private override init() {
        super.init()
        maxConcurrentOperationCount = 1
    }

    override func addOperation(_ op: Operation) {
        if let operation = op as? OPDSRefreshOperation {
            currentOPDSRefreshOperation = operation
        }
        super.addOperation(op)
    }
}

class LibraryOperationBase: Operation {
    internal func updateZimFile(_ zimFile: ZimFile, meta: ZimFileMetaData) {
        zimFile.title = meta.title
        zimFile.groupID = meta.groupIdentifier
        zimFile.fileDescription = meta.fileDescription
        zimFile.languageCode = meta.languageCode
        zimFile.categoryRaw = (ZimFile.Category(rawValue: meta.category) ?? .other).rawValue
        zimFile.creationDate = meta.creationDate
        
        if let creator = meta.creator { zimFile.creator = creator}
        if let publisher = meta.publisher { zimFile.publisher = publisher }
        if let url = meta.downloadURL { zimFile.downloadURL = url.absoluteString }
        if let url = meta.faviconURL { zimFile.faviconURL = url.absoluteString }
        if let faviconData = meta.faviconData { zimFile.faviconData = faviconData }
        if let size = meta.size { zimFile.size.value = size.int64Value }
        if let articleCount = meta.articleCount { zimFile.articleCount.value = articleCount.int64Value }
        if let mediaCount = meta.mediaCount { zimFile.mediaCount.value = mediaCount.int64Value }

        zimFile.hasDetails = meta.hasDetails
        zimFile.hasIndex = meta.hasIndex
        zimFile.hasPictures = meta.hasPictures
        zimFile.hasVideos = meta.hasVideos
    }
}

enum OPDSRefreshError: LocalizedError {
    case retrieve(description: String)
    case parse
    case process

    var errorDescription: String? {
        switch self {
        case .retrieve(let description):
            return description
        case .parse:
            return NSLocalizedString("Library data parsing Error", comment: "")
        case .process:
            return NSLocalizedString("Library data processing error", comment: "")
        }
    }
}
