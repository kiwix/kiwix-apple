//
//  Queries.swift
//  Kiwix
//
//  Created by Chris Li on 12/6/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import RealmSwift

class Queries {
    class func onDeviceZimFiles() -> Results<ZimFile>? {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            return database.objects(ZimFile.self).filter(predicate)
        } catch { return nil }
    }
}
