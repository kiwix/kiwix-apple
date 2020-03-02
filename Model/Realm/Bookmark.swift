//
//  Bookmark.swift
//  Kiwix
//
//  Created by Chris Li on 4/27/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

class Bookmark: Object{
    @objc dynamic var path = ""
    @objc dynamic var zimFile: ZimFile?
    
    @objc dynamic var title = ""
    @objc dynamic var snippet: String?
    @objc dynamic var thumbImagePath: String?
    @objc dynamic var date: Date?
    
    var thumbImageData: Data? {
        guard let thumbImagePath = thumbImagePath, let zimFile = zimFile else {return nil}
        return ZimMultiReader.shared.getContent(bookID: zimFile.id, contentPath: thumbImagePath)?.data
    }
}
