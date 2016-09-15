//
//  iOSExtensions.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// MARK: - CoreData

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
    class var mainQueueContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
}

// MARK: - UI

enum BuildStatus {
    case Alpha, Beta, Release
}

extension UIApplication {
    class var buildStatus: BuildStatus {
        get {
            return .Beta
        }
    }
}

extension UIStoryboard {
    class var library: UIStoryboard {get {return UIStoryboard(name: "Library", bundle: nil)}}
    class var main: UIStoryboard {get {return UIStoryboard(name: "Main", bundle: nil)}}
    class var search: UIStoryboard {get {return UIStoryboard(name: "Search", bundle: nil)}}
    class var setting: UIStoryboard {get {return UIStoryboard(name: "Setting", bundle: nil)}}
    class var welcome: UIStoryboard {get {return UIStoryboard(name: "Welcome", bundle: nil)}}
    
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
    
    func controller<T:UIViewController>(type: T.Type) -> T? {
        return instantiateViewControllerWithIdentifier(String(T)) as? T
    }
}

extension UIColor {
    class var defaultTint: UIColor {return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)}

    class var themeColor: UIColor {
        return UIColor(red: 71.0 / 255.0, green: 128.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
    }
}

class AppColors {
    static let hasPicTintColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    static let hasIndexTintColor = UIColor(red: 0.304706, green: 0.47158, blue: 1, alpha: 1)
    static let theme = UIColor(red: 71/255, green: 128/255, blue: 182/255, alpha: 1)
}
