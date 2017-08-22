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
    
    func addBooks(paths: [String]) {
        for path in paths {
            __addBook(byPath: path)
        }
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
    
    func getSearchSuggestions(searchTerm: String) -> [(title: String, path: String)] {
        guard let suggestions = __getSearchSuggestions(searchTerm) else {return []}
        return suggestions.flatMap { suggestion -> (String, String)? in
            guard let suggestion = suggestion as? Dictionary<String, String>,
                let title = suggestion["title"],
                let path = suggestion["path"] else {return nil}
            return (title, path)
        }
    }
}
