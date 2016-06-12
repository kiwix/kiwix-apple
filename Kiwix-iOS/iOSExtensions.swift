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
    
    class var themeColor: UIColor {
        return UIColor(red: 71.0 / 255.0, green: 128.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
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