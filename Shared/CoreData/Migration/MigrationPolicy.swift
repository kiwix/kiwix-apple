//
//  MigrationPolicy.swift
//  Kiwix
//
//  Created by Chris Li on 4/12/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData

class MigrationPolicy1_5: NSEntityMigrationPolicy {
    func negateBool(_ bool: NSNumber) -> NSNumber {
        let bool = bool.boolValue
        return !bool as NSNumber
    }
}

class MigrationPolicy1_8: NSEntityMigrationPolicy {
    func bookState(_ bool: NSNumber?) -> NSNumber {
        if let bool = bool?.boolValue {
            return bool ? NSNumber(value: 2 as Int) : NSNumber(value: 0 as Int)
        } else {
            return NSNumber(value: 1 as Int)
        }
    }
    
    func path(_ url: String) -> String {
        return URL(string: url)?.path ?? ""
    }
}
