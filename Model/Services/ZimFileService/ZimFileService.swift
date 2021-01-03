//
//  ZimManager.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

extension ZimFileService {
    static let shared = ZimFileService.__sharedInstance()
    
    var ids: [String] {get{ return __getReaderIdentifiers().compactMap({$0 as? String}) }}
    func getFileURL(zimFileID: String) -> URL? { return __getReaderFileURL(zimFileID) }
    
    func add(url: URL) {__addReader(by: url)}
    func remove(id: String) {__removeReader(byID: id)}
    
    func getRedirectedPath(zimFileID: String, contentPath: String) -> String? {
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
