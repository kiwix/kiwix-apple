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
