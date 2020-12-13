//
//  ZimManager.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

typealias ZimFileID = String

extension ZimMultiReader {
    static let shared = ZimMultiReader.__sharedInstance()
    
    var ids: [ZimFileID] {get{ return __getIdentifiers().compactMap({$0 as? ZimFileID}) }}
    func getFileURL(zimFileID: ZimFileID) -> URL? { return __getFileURL(zimFileID) }
    
    func add(url: URL) {__add(by: url)}
    func remove(id: ZimFileID) {__remove(byID: id)}
    
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
    
    // MARK: - meta data
    
    func getZimFileMetaData(id: String) -> ZimFileMetaData? {
        return __getZimFileMetaData(id)
    }
    
    static func getMetaData(url: URL) -> ZimFileMetaData? {
        return __getMetaData(withFileURL: url)
    }
    
    func getMainPageURL(zimFileID: String) -> URL? {
        guard let path = __getMainPagePath(zimFileID) else {return nil}
        return URL(zimFileID: zimFileID, contentPath: path)
    }
    
    func getRandomPageURL(zimFileID: String) -> URL? {
        guard let path = __getRandomPagePath(zimFileID) else {return nil}
        return URL(zimFileID: zimFileID, contentPath: path)
    }
}
