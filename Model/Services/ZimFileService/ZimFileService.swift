//
//  ZimFileService.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

extension ZimFileService {
    static let shared = ZimFileService.__sharedInstance()
    var zimFileIDs: [String] { get { return __getReaderIdentifiers().compactMap({ $0 as? String }) } }
    
    // MARK: - Reader Management
    
    func open(url: URL) { __open(url) }
    func close(id: String) { __close(id) }
    
    // MARK: - Metadata
    
    func getMetaData(id: String) -> ZimFileMetaData? {
        __getMetaData(id)
    }
    
    static func getMetaData(url: URL) -> ZimFileMetaData? {
        __getMetaData(withFileURL: url)
    }
    
    // MARK: - URL
    
    func getFileURL(zimFileID: String) -> URL? {
        __getFileURL(zimFileID)
    }
    
    func getFileURLBookmark(zimFileID: String) -> Data? {
        try? getFileURL(zimFileID: zimFileID)?.bookmarkData()
    }
    
    func getRedirectedURL(url: URL) -> URL? {
        guard let zimFileID = url.host,
              let redirectedPath = __getRedirectedPath(zimFileID, contentPath: url.path) else { return nil }
        return URL(zimFileID: zimFileID, contentPath: redirectedPath)
    }
    
    func getMainPageURL(zimFileID: String) -> URL? {
        guard let path = __getMainPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID, contentPath: path)
    }
    
    func getRandomPageURL(zimFileID: String) -> URL? {
        guard let path = __getRandomPagePath(zimFileID) else { return nil }
        return URL(zimFileID: zimFileID, contentPath: path)
    }
    
    // MARK: - URL Response
    
    func getURLContent(url: URL) -> URLContent? {
        guard let zimFileID = url.host else { return nil }
        return getURLContent(zimFileID: zimFileID, contentPath: url.path)
    }
    
    func getURLContent(zimFileID: String, contentPath: String) -> URLContent? {
        guard let content = __getURLContent(zimFileID, contentPath: contentPath),
              let data = content["data"] as? Data,
              let mime = content["mime"] as? String,
              let length = content["length"] as? Int else { return nil }
        return URLContent(data: data, mime: mime, length: length)
    }
}

struct URLContent {
    let data: Data
    let mime: String
    let length: Int
}

extension URL {
    init?(zimFileID: String, contentPath: String) {
        let baseURLString = "kiwix://" + zimFileID
        guard let encoded = contentPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        self.init(string: encoded, relativeTo: URL(string: baseURLString))
    }

    var isKiwixURL: Bool {
        return scheme?.caseInsensitiveCompare("kiwix") == .orderedSame
    }
}
