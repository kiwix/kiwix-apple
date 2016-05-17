//
//  CoreDataExtension.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    class func fetch<T:NSManagedObject>(fetchRequest: NSFetchRequest, type: T.Type, context: NSManagedObjectContext) -> [T]? {
        do {
            let matches = try context.executeFetchRequest(fetchRequest) as? [T]
            return matches
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    class func insert<T:NSManagedObject>(type: T.Type, context: NSManagedObjectContext) -> T? {
        let className = String(T)
        guard let obj = NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: context) as? T else {return nil}
        return obj
    }
}

extension NSManagedObjectContext {
    func saveInCorrectThreadIfNeeded() {
        performBlock { () -> Void in
            self.saveIfNeeded()
        }
    }
    
    func saveIfNeeded() {
        guard hasChanges else {return}
        do {
            try save()
        } catch let error as NSError {
            print("ObjContext save failed: \(error.localizedDescription)")
        }
    }
    
    func deleteObjects(objects: [NSManagedObject]) {
        for object in objects {
            deleteObject(object)
        }
    }
}