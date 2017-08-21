//
//  ZimManager.swift
//  Kiwix
//
//  Created by Chris Li on 8/21/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

extension ZimManager {
    class var shared: ZimManager {
        return ZimManager.__sharedInstance()
    }
    
    func addBook(path: String) {
        __addBook(byPath: path)
    }
    
    func getReaderIDs() -> [String] {
        return __getReaderIdentifiers().flatMap({$0 as? String})
    }
    
    func getContent(bookID: String, contentPath: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(bookID, contentURL: contentPath),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
    
    func getMainPagePath(bookID: String) -> String? {
        return __getMainPageURL(bookID)
    }
}
