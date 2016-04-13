//
//  AppDelegateObjs.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension UIApplication {
    
    // MARK: - Class Accessor
    class var libraryRefresher: LibraryRefresher {
        get {return appDelegate.libraryRefresher}
    }
    
    class var multiReader: ZIMMultiReader {
        get {return ZIMMultiReader.sharedInstance}
    }
    
    class var globalOperationQueue: OperationQueue {
        get {return appDelegate.globalOperationQueue}
    }
    
    // MARK: - 
    
    class var networkTaskCount: Int {
        get {return appDelegate.networkTaskCount}
        set {appDelegate.networkTaskCount = newValue}
    }
    
    class func updateApplicationIconBadgeNumber() {
        guard let settings = UIApplication.sharedApplication().currentUserNotificationSettings() else {return}
        guard settings.types.contains(UIUserNotificationType.Badge) else {return}
        //UIApplication.sharedApplication().applicationIconBadgeNumber = downloader.taskCount ?? 0
    }
    
    // MARK: - App Delegate Accessor
    
    class var appDelegate: AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
}

