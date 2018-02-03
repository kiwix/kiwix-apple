//
//  ZimManager.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import ProcedureKit

typealias ZimFileID = String

extension ZimMultiReader {
    static let shared = ZimMultiReader()
    
    var ids: [ZimFileID] {get{ return __getIdentifiers().flatMap({$0 as? ZimFileID}) }}
    func getFileURL(zimFileID: ZimFileID) -> URL? { return __getFileURL(zimFileID) }
    
    func add(url: URL) {__add(by: url)}
    func remove(id: ZimFileID) {__remove(byID: id)}
    
    func hasEmbeddedIndex(id: ZimFileID) -> Bool {return __hasEmbeddedIndex(id)}
    func hasExternalIndex(id: ZimFileID) -> Bool {return __hasExternalIndex(id)}
    
    func getContent(bookID: String, contentPath: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(bookID, contentURL: contentPath),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
    
    func getMetaData(id: ZimFileID) -> ZimMetaData? {return __getMetaData(id)}
    
    func getMainPageURL(bookID: String) -> URL? {
        guard let path = __getMainPageURL(bookID) else {return nil}
        return URL(bookID: bookID, contentPath: path)
    }
    
    func startIndexSearch(searchText: String, zimFileIDs: Set<ZimFileID>) {
        __startIndexSearch(searchText, zimFileIDs: zimFileIDs)
    }
    
    func getNextIndexSearchResult() -> SearchResult? {
        guard let result = __getNextIndexSearchResult() as? Dictionary<String, Any>,
            let id = result["id"] as? String,
            let path = result["path"] as? String,
            let title = result["title"] as? String else {return nil}
        return SearchResult(zimFileID: id, path: path, title: title, probability: result["probability"] as? Double, snippet: result["snippet"] as? String)
    }
    
    func getTitleSearchResults(searchText: String, zimFileID: ZimFileID, count: Int) -> [SearchResult] {
        return __getTitleSearchResults(searchText, zimFileID: zimFileID, count: UInt32(count)).flatMap { suggestion -> SearchResult? in
            guard let suggestion = suggestion as? Dictionary<String, String>,
                let id = suggestion["id"],
                let title = suggestion["title"],
                let path = suggestion["path"] else {return nil}
            return SearchResult(zimFileID: id, path: path, title: title)
        }
    }
}
