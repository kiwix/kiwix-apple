//
//  Bookmark.swift
//  Kiwix
//
//  Created by Chris Li on 4/27/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

class Bookmark: Object, ObjectKeyIdentifiable {
    @Persisted var path = ""
    @Persisted var zimFile: ZimFile?
    
    @Persisted var title = ""
    @Persisted var snippet: String?
    @Persisted var thumbImagePath: String?
    @Persisted var date: Date?
}
