//
//  Database.swift
//  iOS
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

extension Realm {
    static func resetDatabase() {
        guard let url = Realm.defaultConfig.fileURL else {return}
        try? FileManager.default.removeItem(at: url)
    }
    
    static let defaultConfig: Realm.Configuration = {
        var config = Realm.Configuration(schemaVersion: 1)
        config.fileURL = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("realm")
        return config
    }()
}
