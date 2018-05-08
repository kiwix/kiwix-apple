//
//  ZimFileLanguage.swift
//  iOS
//
//  Created by Chris Li on 5/3/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

class ZimFileLanguage: Object {
    @objc dynamic var code = ""
    @objc dynamic var isVisible = false
    let zimFiles = LinkingObjects(fromType: ZimFile.self, property: "language")
    
    override static func primaryKey() -> String? {
        return "code"
    }
}
