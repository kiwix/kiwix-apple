//
//  RealmConfig.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import RealmSwift

extension Realm {
    static let defaultConfig: Realm.Configuration = {
        // Configure Migrations
        var config = Realm.Configuration(
            schemaVersion: 5,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 4) {
                    migration.renameProperty(onType: ZimFile.className(), from: "id", to: "fileID")
                }
                if (oldSchemaVersion < 5) {
                    migration.enumerateObjects(ofType: ZimFile.className()) { oldObject, newObject in
                        newObject?["creationDate"] = oldObject?["creationDate"] ?? Date()
                        newObject?["size"] = oldObject?["size"] ?? 0
                        newObject?["articleCount"] = oldObject?["articleCount"] ?? 0
                        newObject?["mediaCount"] = oldObject?["mediaCount"] ?? 0
                        newObject?["creator"] = oldObject?["creator"] ?? ""
                        newObject?["publisher"] = oldObject?["publisher"] ?? ""
                    }
                }
            }
        )
        
        // Configure realm database path
        let applicationSupport = try! FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        config.fileURL = applicationSupport.appendingPathComponent("kiwix.realm")
        
        return config
    }()
}
