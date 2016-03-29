//
//  Extensions.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// MARK: - UI

extension UIStoryboard {
    class var main: UIStoryboard {get {return UIStoryboard(name: "Main", bundle: nil)}}
    class var library: UIStoryboard {get {return UIStoryboard(name: "Library", bundle: nil)}}
    class var setting: UIStoryboard {get {return UIStoryboard(name: "Setting", bundle: nil)}}
    class var help: UIStoryboard {get {return UIStoryboard(name: "Help", bundle: nil)}}
    
    func initViewController<T:UIViewController>(type: T.Type) -> T? {
        guard let className = NSStringFromClass(T).componentsSeparatedByString(".").last else {
            print("NSManagedObjectExtension: Unable to get class name")
            return nil
        }
        return instantiateViewControllerWithIdentifier(className) as? T
    }
    
    func initViewController<T:UIViewController>(identifier: String, type: T.Type) -> T? {
        return instantiateViewControllerWithIdentifier(identifier) as? T
    }
}

extension UIColor {
    class var havePicTintColor: UIColor {
        return UIColor(red: 255.0/255.0, green: 153.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    }
}

extension UITableView {
    
    func setBackgroundText(text: String?) {
        let label = UILabel()
        label.textAlignment = .Center
        label.text = text
        label.font = UIFont.boldSystemFontOfSize(20.0)
        label.numberOfLines = 0
        label.textColor = UIColor.grayColor()
        backgroundView = label
    }
}

// MARK: - View Controller

extension UIAlertController {
    convenience init(title: String, message: String, style: UIAlertControllerStyle = .Alert, actions:[UIAlertAction]) {
        self.init(title: title, message: message , preferredStyle: style)
        for action in actions {addAction(action)}
    }
}

// MARK: - Model

extension NSLocale {
    class var preferredLangCodes: [String] {
        let preferredLangNames = self.preferredLanguages()
        var preferredLangCodes = Set<String>()
        for lang in preferredLangNames {
            guard let code = lang.componentsSeparatedByString("-").first else {continue}
            preferredLangCodes.insert(NSLocale.canonicalLanguageIdentifierFromString(code))
        }
        return Array(preferredLangCodes)
    }
}

extension NSBundle {
    class var shortVersionString: String {
        return (NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String) ?? ""
    }
}

// MARK: - Core Data

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
    
    class func fetchAll<T:NSManagedObject>(context: NSManagedObjectContext) -> [T]? {
        let className = String(T)
        let fetchRequest = NSFetchRequest(entityName: className)
        return fetch(fetchRequest, type: T.self, context: context)
    }
    
    class func insert<T:NSManagedObject>(type: T.Type, context: NSManagedObjectContext) -> T? {
        let className = String(T)
        guard let obj = NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: context) as? T else {return nil}
        return obj
    }
}

extension NSFetchedResultsController {
    
    func performFetch(deleteCache deleteCache: Bool) {
        do {
            if deleteCache {
                guard let cacheName = cacheName else {return}
                NSFetchedResultsController.deleteCacheWithName(cacheName)
            }
            
            try performFetch()
        } catch let error as NSError {
            print("FetchedResultController performFetch failed: \(error.localizedDescription)")
        }
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