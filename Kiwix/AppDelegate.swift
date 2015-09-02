//
//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSURLProtocol.registerClass(KiwixURLProtocol)
        ZimMultiReader.sharedInstance
        Downloader.sharedInstance
        setupNotification()
        Updater.updateToVersion1_1()
        
//        if let launchOptions = launchOptions, let localNotification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
//            if let userInfo = localNotification.userInfo, let idString = userInfo["idString"] {
//                // TODO: load main page
//            }
//        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        Utilities.updateApplicationIconBadgeNumber()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        LibraryRefresher.sharedInstance.refreshLibraryIfNecessary()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        Downloader.sharedInstance.saveTotalBytesWrittenToCoredata()
        Utilities.updateApplicationIconBadgeNumber()
        self.saveContext()
    }
    
    // MARK: - Notification
    
    var completionHandler: (() -> Void)?
    
    func setupNotification() {
        let openLibrary = UIMutableUserNotificationAction()
        openLibrary.identifier = "OPEN_BOOK_LIBRARY"
        openLibrary.title = "Open Library"
        openLibrary.activationMode = .Foreground
        
        let openMainPage = UIMutableUserNotificationAction()
        openMainPage.identifier = "OPEN_MAIN_PAGE"
        openMainPage.title = "Open Main Page"
        openMainPage.activationMode = .Foreground
        
        let bookDownloadFinishCategory = UIMutableUserNotificationCategory()
        bookDownloadFinishCategory.identifier = "KIWIX_BOOK_DOWNLOAD_FINISH"
//        bookDownloadFinishCategory.setActions([openLibrary, openMainPage], forContext: .Minimal)
        let settings = UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: Set(arrayLiteral: bookDownloadFinishCategory))
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        Downloader.sharedInstance.rejoinSessionWithIdentifier(identifier)
        self.completionHandler = completionHandler
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        if notification.category == "KIWIX_BOOK_DOWNLOAD_FINISH" {
            if identifier == "OPEN_BOOK_LIBRARY" {
                if let mainViewController = (self.window?.rootViewController as? UINavigationController)?.topViewController {
                    if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                        mainViewController.performSegueWithIdentifier("ShowLibrary", sender: mainViewController)
                    } else {
                        
                    }
                }
            } else if identifier == "OPEN_MAIN_PAGE" {
                if let idString = responseInfo["idString"] {
                    print(idString)
                }
            }
        }
        completionHandler()
    }
    
    // MARK: - Core Data stack

    lazy var applicationLibraryDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "self.Kiwix" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)
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
        let url = self.applicationLibraryDirectory.URLByAppendingPathComponent("Kiwix.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        do {
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
            abort()
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
                abort()
            }
        }
    }

}

