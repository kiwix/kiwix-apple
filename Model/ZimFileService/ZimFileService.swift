// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Foundation

@globalActor actor ZimActor {
    static let shared = ZimActor()
}

@ZimActor
struct ZimFileService {
    static let shared = ZimFileService()
    /// Shared ZimFileService instance
    private let instance = ZimService.__sharedInstance()

    /// IDs of current local zim files (not necessaraly with opened Archive)
    private var fileIDs: [UUID] { instance.__getReaderIdentifiers().compactMap({ $0 as? UUID }) }

    // MARK: - Reader Management

    /// Revalidates the zim file url bookmark data (returned)
    /// and stores the zim file url in ZimFileService associated with the zim UUID
    /// - Parameter bookmark: url bookmark data of the zim file to open
    /// - Returns: new url bookmark data if the one used to open the zim file is stale
    @discardableResult
    func revalidate(fileURLBookmark data: Data, for uuid: UUID) throws -> Data? {
        // resolve url
        var isStale: Bool = false
        #if os(macOS)
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &isStale
        ) else { throw ZimFileOpenError.missing }
        #else
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            throw ZimFileOpenError.missing
        }
        #endif
        instance.__store(url, with: uuid)
        return isStale ? ZimFileService.getFileURLBookmarkData(for: url) : nil
    }

    func openArchive(zimFileID: UUID) -> UUID? {
        instance.__open(zimFileID)
    }
    
    func createSpellingIndex(zimFileID: UUID, cacheDir: URL) {
        instance.__createSpellingIndex(zimFileID, cachePath: cacheDir.path())
    }

    /// Close a zim file
    /// - Parameter fileID: ID of the zim file to close
    func close(fileID: UUID) { instance.__close(fileID) }

    // MARK: - Metadata

    static func getMetaData(url: URL) -> ZimFileMetaData? {
        ZimService.__getMetaData(withFileURL: url)
    }

    // MARK: - URL System Bookmark

    /// System URL bookmark for the ZIM file itself
    /// "bookmark data that can later be resolved into a URL object for a file
    /// even if the user moves or renames it"
    /// Not to be confused with the article bookmarks
    /// - Parameter url: file system URL
    /// - Returns: data that can later be resolved into a URL object
    static func getFileURLBookmarkData(for url: URL) -> Data? {
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
        return instance.__getFileURL(zimFileID)
    }

    func getRedirectedURL(url: URL) -> URL? {
        guard let zimFileID = url.zimFileID,
              let redirectedPath = instance.__getRedirectedPath(zimFileID, contentPath: url.contentPath) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: redirectedPath)
    }

    func getMainPageURL(zimFileID: UUID? = nil) -> URL? {
        guard let zimFileID = zimFileID ?? fileIDs.randomElement(),
              let path = instance.__getMainPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: path)
    }

    func getRandomPageURL(zimFileID: UUID? = nil) -> URL? {
        guard let zimFileID = zimFileID ?? fileIDs.randomElement(),
              let path = instance.__getRandomPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID.uuidString, contentPath: path)
    }

    // MARK: - URL Response

    func getURLContent(url: URL) -> URLContent? {
        guard let zimFileID = url.host else { return nil }
        return getURLContent(zimFileID: zimFileID, contentPath: url.contentPath)
    }

    func getURLContent(url: URL, start: UInt, end: UInt) -> URLContent? {
        guard let zimFileID = url.host else { return nil }
        return getURLContent(zimFileID: zimFileID, contentPath: url.contentPath, start: start, end: end)
    }

    func getContentSize(url: URL) -> NSNumber? {
        guard let zimFileUUID = url.zimFileID else { return nil }
        return instance.__getContentSize(zimFileUUID, contentPath: url.contentPath)
    }

    func getDirectAccessInfo(url: URL) -> DirectAccessInfo? {
        guard let zimFileUUID = url.zimFileID,
              let directAccess = instance.__getDirectAccess(zimFileUUID, contentPath: url.contentPath),
              let path: String = directAccess["path"] as? String,
              let offset: UInt = directAccess["offset"] as? UInt
        else {
            return nil
        }
        return DirectAccessInfo(path: path, offset: offset)
    }

    func getContentMetaData(url: URL) -> URLContentMetaData? {
        guard let zimFileUUID = url.zimFileID,
              let content = instance.__getMetaData(zimFileUUID, contentPath: url.contentPath),
              let mime = content["mime"] as? String,
              let size = content["size"] as? UInt,
              let title = content["title"] as? String else { return nil }
        let zimFileModificationDate = content["zimFileDate"] as? Date
        return URLContentMetaData(
            mime: mime,
            size: size,
            zimTitle: title,
            lastModified: zimFileModificationDate
        )
    }

    func getURLContent(zimFileID: String, contentPath: String, start: UInt = 0, end: UInt = 0) -> URLContent? {
        guard let zimFileID = UUID(uuidString: zimFileID),
              let content = instance.__getContent(zimFileID, contentPath: contentPath, start: start, end: end),
              let data = content["data"] as? Data,
              let start = content["start"] as? UInt,
              let end = content["end"] as? UInt else { return nil }
        return URLContent(data: data, start: start, end: end)
    }
    
    // MARK: ZIM integrity check
    func checkIntegrity(zimFileID: UUID) -> Bool {
        instance.__checkIntegrity(zimFileID)
    }
}

enum ZimFileOpenError: Error {
    case missing
}
