//
//  CoreDataExtension.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    class func fetch<T:NSManagedObject>(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>, type: T.Type, context: NSManagedObjectContext) -> [T]? {
        do {
            let matches = try context.fetch(fetchRequest) as? [T]
            return matches
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    class func insert<T:NSManagedObject>(_ type: T.Type, context: NSManagedObjectContext) -> T? {
        let className = String(describing: T.self)
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: className, into: context) as? T else {return nil}
        return obj
    }
}

extension NSManagedObjectContext {
    func saveInCorrectThreadIfNeeded() {
        perform { () -> Void in
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
    
    func deleteObjects(_ objects: [NSManagedObject]) {
        for object in objects {
            delete(object)
        }
    }
}
