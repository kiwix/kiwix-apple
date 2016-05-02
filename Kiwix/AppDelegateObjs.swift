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
    
    class var globalOperationQueue: OperationQueue {
        get {return appDelegate.globalOperationQueue}
    }
    
    // MARK: - 

    
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

