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
            return .Alpha
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

extension UINavigationBar {
    func hideBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView!.hidden = true
    }
    
    func showBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView!.hidden = false
    }
    
    private func hairlineImageViewInNavigationBar(view: UIView) -> UIImageView? {
        if view.isKindOfClass(UIImageView) && view.bounds.height <= 1.0 {
            return (view as! UIImageView)
        }
        
        let subviews = (view.subviews as [UIView])
        for subview: UIView in subviews {
            if let imageView: UIImageView = hairlineImageViewInNavigationBar(subview) {
                return imageView
            }
        }
        return nil
    }
}

extension UIToolbar {
    func hideHairline() {
        let navigationBarImageView = hairlineImageViewInToolbar(self)
        navigationBarImageView!.hidden = true
    }
    
    func showHairline() {
        let navigationBarImageView = hairlineImageViewInToolbar(self)
        navigationBarImageView!.hidden = false
    }
    
    private func hairlineImageViewInToolbar(view: UIView) -> UIImageView? {
        if view.isKindOfClass(UIImageView) && view.bounds.height <= 1.0 {
            return (view as! UIImageView)
        }
        
        let subviews = (view.subviews as [UIView])
        for subview: UIView in subviews {
            if let imageView: UIImageView = hairlineImageViewInToolbar(subview) {
                return imageView
            }
        }
        return nil
    }
}

// MARK: - View Controller

extension UIAlertController {
    convenience init(title: String, message: String, style: UIAlertControllerStyle = .Alert, actions:[UIAlertAction]) {
        self.init(title: title, message: message , preferredStyle: style)
        for action in actions {addAction(action)}
    }
}