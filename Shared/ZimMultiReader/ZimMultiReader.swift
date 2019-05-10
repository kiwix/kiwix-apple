//
//  ZimManager.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

typealias ZimFileID = String

extension ZimMultiReader {
    static let shared = ZimMultiReader()
    
    var ids: [ZimFileID] {get{ return __getIdentifiers().compactMap({$0 as? ZimFileID}) }}
    func getFileURL(zimFileID: ZimFileID) -> URL? { return __getFileURL(zimFileID) }
    
    func add(url: URL) {__add(by: url)}
    func remove(id: ZimFileID) {__remove(byID: id)}
    
    func hasEmbeddedIndex(id: ZimFileID) -> Bool {return __hasEmbeddedIndex(id)}
    
    @available(*, deprecated, message: "External index is no longer supported")
    func hasExternalIndex(id: ZimFileID) -> Bool {return __hasExternalIndex(id)}
    
    func getRedirectedPath(zimFileID: ZimFileID, contentPath: String) -> String? {
        return __getRedirectedPath(zimFileID, contentPath: contentPath)
    }
    
    func getContent(bookID: String, contentPath: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(bookID, contentURL: contentPath),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
    
    func getMetaData(id: ZimFileID) -> [String: Any] {return ( __getMetaData(id) as? [String: Any]) ?? [String: Any]() }
    
    func getMainPageURL(zimFileID: String) -> URL? {
        guard let path = __getMainPagePath(zimFileID) else {return nil}
        return URL(bookID: zimFileID, contentPath: path)
    }
    
    func startIndexSearch(searchText: String, zimFileIDs: Set<ZimFileID>) {
        __startIndexSearch(searchText, zimFileIDs: zimFileIDs)
    }
    
    func getNextIndexSearchResult(extractSnippet: Bool) -> SearchResult? {
        guard let result = __getNextIndexSearchResult(withSnippet: extractSnippet) as? Dictionary<String, Any>,
            let id = result["id"] as? String,
            let path = result["path"] as? String,
            let title = result["title"] as? String else {return nil}
        return SearchResult(zimFileID: id, path: path, title: title, probability: result["probability"] as? Double, snippet: result["snippet"] as? String)
    }
    
    func getTitleSearchResults(searchText: String, zimFileID: ZimFileID, count: Int) -> [SearchResult] {
        return __getTitleSearchResults(searchText, zimFileID: zimFileID, count: UInt32(count)).compactMap { suggestion -> SearchResult? in
            guard let suggestion = suggestion as? Dictionary<String, String>,
                let id = suggestion["id"],
                let title = suggestion["title"],
                let path = suggestion["path"] else {return nil}
            return SearchResult(zimFileID: id, path: path, title: title)
        }
    }
}
