//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris on 12/11/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData
import PSOperations

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OperationQueueDelegate {
    
    var window: UIWindow?
    var mainController: MainController? {
        return (window?.rootViewController as? UINavigationController)?.topViewController as? MainController
    }
    
    private let recentShortcutTypeString = "org.kiwix.recent"
    
    func recordActiveSession() {
        Preference.activeUseHistory.append(NSDate()) 
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSURLProtocol.registerClass(KiwixURLProtocol)
        Network.sharedInstance.restoreProgresses()
        
        // Register notification
        let settings = UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil) // Here are the notification permission the app wants
        application.registerUserNotificationSettings(settings)
        
        return true
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        switch shortcutItem.type {
        case "org.kiwix.search":
            mainController?.hidePresentedController(true, completion: { 
                self.mainController?.showSearch()
                completionHandler(true)
            })
        case "org.kiwix.bookmarks":
            mainController?.hidePresentedController(true, completion: {
                self.mainController?.hideSearch()
                self.mainController?.showBookmarkTBVC()
                completionHandler(true)
            })
        case recentShortcutTypeString:
            guard let urlString = shortcutItem.userInfo?["URL"] as? String else {completionHandler(false); return}
            mainController?.load(NSURL(string: urlString))
            completionHandler(true)
        default:
            completionHandler(false)
            return
        }
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        // Here we get what notification permission user currently allows
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Active
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(AppDelegate.recordActiveSession), userInfo: nil, repeats: false)
        removeAllDynamicShortcutItems()
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        //UIApplication.updateApplicationIconBadgeNumber()
        
        if let article = mainController?.article {
            addRecentArticleShortCutItem(article)
        }
    }
    
    //    class func updateApplicationIconBadgeNumber() {
    //        guard let settings = UIApplication.sharedApplication().currentUserNotificationSettings() else {return}
    //        guard settings.types.contains(UIUserNotificationType.Badge) else {return}
    //        //UIApplication.sharedApplication().applicationIconBadgeNumber = downloader.taskCount ?? 0
    //    }
    
    // MARK: - Shotcut Items 
    
    func removeAllDynamicShortcutItems() {
        guard let items = UIApplication.sharedApplication().shortcutItems?.filter({$0.type == recentShortcutTypeString}) else {return}
        for item in items {
            guard let index = UIApplication.sharedApplication().shortcutItems?.indexOf(item) else {continue}
            UIApplication.sharedApplication().shortcutItems?.removeAtIndex(index)
        }
    }
    
    func addRecentArticleShortCutItem(article: Article) {
        guard let title = article.title, let url = article.urlString else {return}
        let icon = UIApplicationShortcutIcon(templateImageName: "Recent")
        let item = UIMutableApplicationShortcutItem(type: recentShortcutTypeString, localizedTitle: title, localizedSubtitle: "", icon: icon, userInfo: ["URL": url])
        UIApplication.sharedApplication().shortcutItems?.append(item)
    }

    // MARK: - Background
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        Network.sharedInstance.rejoinSessionWithIdentifier(identifier, completionHandler: completionHandler)
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "self.Kiwix" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Kiwix", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let libDirPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let libDirURL = NSURL(fileURLWithPath: libDirPath, isDirectory: true)
        let url = libDirURL.URLByAppendingPathComponent("kiwix.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

