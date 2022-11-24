//
//  ZimFileService.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017-2022 Chris Li. All rights reserved.
//

/// A service to interact with zim files
extension ZimFileService {
    /// Shared ZimFileService instance
    static let shared = ZimFileService.__sharedInstance()
    
    /// IDs of currently opened zim files
    var fileIDs: [UUID] { get { return __getReaderIdentifiers().compactMap({ $0 as? UUID }) } }
    
    // MARK: - Reader Management
    
    /// Open a zim file from bookmark data
    /// - Parameter bookmark: url bookmark data of the zim file to open
    /// - Returns: new url bookmark data if the one used to open the zim file is stale
    @discardableResult
    func open(bookmark: Data) throws -> Data? {
        // resolve url
        var isStale: Bool = false
        #if os(macOS)
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &isStale
        ) else { throw ZimFileOpenError.missing }
        #else
        guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
            throw ZimFileOpenError.missing
        }
        #endif
        
        __open(url)
        return isStale ? ZimFileService.getBookmarkData(url: url) : nil
    }
    
    /// Close a zim file
    /// - Parameter fileID: ID of the zim file to close
    func close(fileID: UUID) { __close(fileID) }
    
    // MARK: - Metadata
    
    func getMetaData(id: UUID) -> ZimFileMetaData? {
        __getMetaData(id)
    }
    
    func getFavicon(id: UUID) -> Data? {
        __getFavicon(id)
    }

    static func getMetaData(url: URL) -> ZimFileMetaData? {
        __getMetaData(withFileURL: url)
    }
    
    // MARK: - URL Bookmark
    
    static func getBookmarkData(url: URL) -> Data? {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        #if os(macOS)
        return try? url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #else
        return try? url.bookmarkData(options: .minimalBookmark)
        #endif
    }
    
    // MARK: - URL Retrieve
    
    func getFileURL(zimFileID: UUID) -> URL? {
        return __getFileURL(zimFileID)
    }
    
    func getRedirectedURL(url: URL) -> URL? {
        guard let zimFileID = url.host,
              let zimFileID = UUID(uuidString: zimFileID),
              let redirectedPath = __getRedirectedPath(zimFileID, contentPath: url.path) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: redirectedPath)
    }
    
    func getMainPageURL(zimFileID: UUID? = nil) -> URL? {
        guard let zimFileID = zimFileID ?? fileIDs.randomElement(),
              let path = __getMainPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: path)
    }
    
    func getRandomPageURL(zimFileID: UUID? = nil) -> URL? {
        guard let zimFileID = zimFileID ?? fileIDs.randomElement(),
              let path = __getRandomPagePath(zimFileID) else { return nil }
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

enum ZimFileOpenError: Error {
    case missing
}
