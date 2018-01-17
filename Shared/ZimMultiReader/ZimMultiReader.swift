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
    
    func hasIndex(id: ZimFileID) -> Bool {return __hasIndex(id)}
    
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
    
    func startIndexSearch(term: String) {__startIndexSearch(term)}
    
    func getNextIndexSearchResult() -> SearchResult? {
        guard let result = __getNextIndexSearchResult() as? Dictionary<String, String>,
            let id = result["id"],
            let path = result["path"],
            let title = result["title"] else {return nil}
        return SearchResult(zimFileID: id, path: path, title: title, snippet: result["snippet"])
    }
    
    func getTitleSearchResults(term: String) -> [SearchResult] {
        return __getTitleSearchResults(term).flatMap { suggestion -> SearchResult? in
            guard let suggestion = suggestion as? Dictionary<String, String>,
                let id = suggestion["id"],
                let title = suggestion["title"],
                let path = suggestion["path"] else {return nil}
            return SearchResult(zimFileID: id, path: path, title: title)
        }
    }
    
}
