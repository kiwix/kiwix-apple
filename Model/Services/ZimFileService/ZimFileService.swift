//
//  ZimFileService.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

extension ZimFileService {
    static let shared = ZimFileService.__sharedInstance()
    var zimFileIDs: [UUID] { get { return __getReaderIdentifiers().compactMap({ $0 as? UUID }) } }
    
    // MARK: - Reader Management
    
    func open(url: URL) { __open(url) }
    
    @discardableResult
    func open(bookmark: Data) -> Data? {
        var isStale: Bool = false
        #if os(macOS)
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        #else
        guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else { return nil }
        #endif
        open(url: url)
        return isStale ? ZimFileService.getBookmarkData(url: url) : nil
    }
    
    func close(id: String) { if let fileID = UUID(uuidString: id) { __close(fileID) } }
    func close(id: UUID) { __close(id) }
    
    // MARK: - Metadata
    
    func getMetaData(id: UUID) -> ZimFileMetaData? {
        __getMetaData(id)
    }
    
    static func getMetaData(url: URL) -> ZimFileMetaData? {
        __getMetaData(withFileURL: url)
    }
    
    // MARK: - URL
    
    static func getBookmarkData(url: URL) -> Data? {
        #if os(macOS)
        try? url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #else
        try? url.bookmarkData()
        #endif
    }
    
    func getFileURL(zimFileID: String) -> URL? {
        guard let zimFileID = UUID(uuidString: zimFileID) else { return nil }
        return __getFileURL(zimFileID)
    }
    
    func getFileURLBookmark(zimFileID: String) -> Data? {
        try? getFileURL(zimFileID: zimFileID)?.bookmarkData()
    }
    
    func getRedirectedURL(url: URL) -> URL? {
        guard let zimFileID = url.host,
              let zimFileID = UUID(uuidString: zimFileID),
              let redirectedPath = __getRedirectedPath(zimFileID, contentPath: url.path) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: redirectedPath)
    }
    
    func getMainPageURL(zimFileID: String) -> URL? {
        guard let zimFileID = UUID(uuidString: zimFileID), let path = __getMainPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: path)
    }
    
    func getRandomPageURL(zimFileID: String) -> URL? {
        guard let zimFileID = UUID(uuidString: zimFileID), let path = __getRandomPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: path)
    }
    
    // MARK: - URL Response
    
    func getURLContent(url: URL) -> URLContent? {
        guard let zimFileID = url.host else { return nil }
        return getURLContent(zimFileID: zimFileID, contentPath: url.path)
    }
    
    func getURLContent(zimFileID: String, contentPath: String) -> URLContent? {
        guard let zimFileID = UUID(uuidString: zimFileID),
              let content = __getContent(zimFileID, contentPath: contentPath),
              let data = content["data"] as? Data,
              let mime = content["mime"] as? String,
              let length = content["length"] as? Int else { return nil }
        return URLContent(data: data, mime: mime, length: length)
    }
}
