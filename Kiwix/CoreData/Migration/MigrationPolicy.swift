//
//  MigrationPolicy.swift
//  Kiwix
//
//  Created by Chris Li on 4/12/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData

class MigrationPolicy1_5: NSEntityMigrationPolicy {
    func negateBool(bool: NSNumber) -> NSNumber {
        let bool = bool.boolValue
        return !bool
    }
}

class MigrationPolicy1_8: NSEntityMigrationPolicy {
    func bookState(bool: NSNumber?) -> NSNumber {
        if let bool = bool?.boolValue {
            return bool ? NSNumber(integer: 2) : NSNumber(integer: 0)
        } else {
            return NSNumber(integer: 1)
        }
    }
    
    func articlePath(url: String) -> String {
        return NSURL(string: url)!.path!
    }
}
