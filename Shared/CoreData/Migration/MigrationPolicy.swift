//
//  MigrationPolicy.swift
//  Kiwix
//
//  Created by Chris Li on 4/12/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData

class MigrationPolicy1_5: NSEntityMigrationPolicy {
    @objc func negateBool(_ bool: NSNumber) -> NSNumber {
        let bool = bool.boolValue
        return !bool as NSNumber
    }
}

class MigrationPolicy1_8: NSEntityMigrationPolicy {
    @objc func bookState(_ bool: NSNumber?) -> NSNumber {
        if let bool = bool?.boolValue {
            return bool ? NSNumber(value: 2 as Int) : NSNumber(value: 0 as Int)
        } else {
            return NSNumber(value: 1 as Int)
        }
    }
    
    @objc func path(_ url: String) -> String {
        return URL(string: url)?.path ?? ""
    }
}

class MigrationPolicy1_9: NSEntityMigrationPolicy {
    @objc func bookCategory(urlString: String?) -> String? {
        guard let urlString = urlString,
            let components = URL(string: urlString)?.pathComponents,
            components.indices ~= 2 else {return nil}
        if let category = BookCategory(rawValue: components[2]) {
            return category.rawValue
        } else if components[2] == "stack_exchange" {
            return BookCategory.stackExchange.rawValue
        } else {
            return BookCategory.other.rawValue
        }
    }
    
    @objc func bookStateRaw(book: Book) -> NSNumber? {
        var newStateRaw = BookState.cloud.rawValue
        if let oldStateRaw = (book.value(forKey: "stateRaw") as? NSNumber)?.intValue {
            if oldStateRaw == 1 {
                newStateRaw = 2
            } else if oldStateRaw == 2 {
                newStateRaw = 5
            } else if oldStateRaw == 3 {
                newStateRaw = 6
            }
        }
        
        
        return NSNumber(integerLiteral: newStateRaw)
    }
}
