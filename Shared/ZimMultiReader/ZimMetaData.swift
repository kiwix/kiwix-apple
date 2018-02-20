//
//  ZimMetaData.swift
//  Kiwix
//
//  Created by Chris Li on 10/24/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

extension ZimMetaData {
    var id: String { return __getID() }
    var mainPageURL: URL? { return URL(string: __getMainPageURL()) }
    var title: String { return __getTitle() }
    var bookDescription: String { return __getDescription() }
    var language: String { return __getLanguage() }
    var name: String { return __getName() }
    var tags: [String] { return __getTags().components(separatedBy: ";") }
    var date: Date? { return ZimMetaData.dateFormatter.date(from: __getDate()) }
    var creator: String { return __getCreator() }
    var publisher: String { return __getPublisher() }
    var favicon: Data? { return __getFavicon() }
    
    var fileSize: Int64 { return Int64(__getFileSize()) }
    var articleCount: Int64 { return Int64(__getArticleCount()) }
    var mediaCount: Int64 { return Int64(__getMediaCount()) }
    var globalCount: Int64 { return Int64(__getGlobalCount()) }
    
    convenience init?(fileURL: URL) {
        self.init(__zimFileURL: fileURL)
    }
    
    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
}
