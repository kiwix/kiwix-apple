//
//  OSXExtensions.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa
import CoreData
import AppKit

extension NSManagedObjectContext {
    class var mainQueueContext: NSManagedObjectContext {
        return (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
}