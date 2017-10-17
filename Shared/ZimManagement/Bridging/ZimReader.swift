//
//  ZimReader.swift
//  Kiwix
//
//  Created by Chris Li on 10/16/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

extension ZimReader {
    var id: String { return __getID() }
    var mainPageURL: URL? { return URL(string: __getMainPageURL()) }
    var title: String { return __getTitle() }
    var bookDescription: String { return __getDescription() }
    var language: String { return __getLanguage() }
    var name: String { return __getName() }
    var tags: [String] { return __getTags().components(separatedBy: ";") }
    var date: Date? { return ZimReader.dateFormatter.date(from: __getDate()) }
    var creator: String { return __getCreator() }
    var publisher: String { return __getPublisher() }
    var favicon: Data? { return __getFavicon() }
    var articleCount: Int64 { return Int64(__getArticleCount()) }
    var mediaCount: Int64 { return Int64(__getMediaCount()) }
    var globalCount: Int64 { return Int64(__getGlobalCount()) }
    
    convenience init?(fileURL: URL) {
        self.init(__zimFileURL: fileURL)
    }
    
    func getContent(path: String) -> (data: Data, mime: String, length: Int)? {
        guard let content = __getContent(path),
            let data = content["data"] as? Data,
            let mime = content["mime"] as? String,
            let length = content["length"] as? Int else {return nil}
        return (data, mime, length)
    }
    
    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}
