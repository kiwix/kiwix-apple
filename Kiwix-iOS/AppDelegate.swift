//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris on 12/11/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import ProcedureKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var mainController: MainController? {
        return (window?.rootViewController as? UINavigationController)?.topViewController as? MainController
    }
    
    private let recentShortcutTypeString = "org.kiwix.recent"
    
    func recordActiveSession() {
        Preference.activeUseHistory.append(Date()) 
    }
    
    func registerNotification() {
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { _ in })
        } else {
            let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    func registerCloudKit() {
        if #available(iOS 10, *) {
            guard !Preference.hasSubscribedToCloudKitChanges else {return}
            
            let subscription = CKDatabaseSubscription(subscriptionID: "")
            let notificationInfo = CKNotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
            operation.modifySubscriptionsCompletionBlock = { savedSubscriptions, _, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    Preference.hasSubscribedToCloudKitChanges = true
                }
            }
            
            let database = CKContainer(identifier: "iCloud.org.kiwix").privateCloudDatabase
            database.add(operation)
        }
    }
    
    // MARK: -

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        URLProtocol.registerClass(KiwixURLProtocol)
//        Network.shared
        
        // Register notification
        if let _ = Preference.libraryLastRefreshTime { registerNotification() }
        
        // Set background refresh interval
        application.setMinimumBackgroundFetchInterval(86400)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        // Here we get what notification permission user currently allows
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        guard url.isKiwixURL else {return false}
//        let operation = ArticleLoadOperation(url: url)
//        GlobalQueue.shared.add(load: operation)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == "org.kiwix.kiwix.article-view" {
            guard let navController = window?.rootViewController as? UINavigationController,
                let controller = navController.topViewController as? MainController else {return false}
            controller.restoreUserActivityState(userActivity)
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Active
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(AppDelegate.recordActiveSession), userInfo: nil, repeats: false)
        ZimMultiReader.shared.startScan()
        removeAllDynamicShortcutItems()
    }

    func applicationWillResignActive(_ application: UIApplication) {
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
    
    func addRecentArticleShortCutItem(_ article: Article) {
        guard let title = article.title, let url = article.url?.absoluteString else {return}
        let icon = UIApplicationShortcutIcon(templateImageName: "Recent")
        let item = UIMutableApplicationShortcutItem(type: recentShortcutTypeString,
                                                    localizedTitle: title, localizedSubtitle: "",
                                                    icon: icon,
                                                    userInfo: ["URL": url])
        UIApplication.shared.shortcutItems?.append(item)
    }
    
    func removeAllDynamicShortcutItems() {
        guard let items = UIApplication.shared.shortcutItems?.filter({$0.type == recentShortcutTypeString}) else {return}
        for item in items {
            guard let index = UIApplication.shared.shortcutItems?.index(of: item) else {continue}
            UIApplication.shared.shortcutItems?.remove(at: index)
        }
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "org.kiwix.search":
            self.mainController?.showSearch(animated: false)
            completionHandler(true)
        case "org.kiwix.bookmarks":
            self.mainController?.showBookmarkController()
            completionHandler(true)
        case recentShortcutTypeString:
            guard let urlString = shortcutItem.userInfo?["URL"] as? String,
                let url = URL(string: urlString) else {completionHandler(false); return}
//            let operation = ArticleLoadOperation(url: url)
//            GlobalQueue.shared.add(load: operation)
            completionHandler(true)
        default:
            completionHandler(false)
            return
        }
    }

    // MARK: - Background
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
//        Network.shared.rejoinSessionWithIdentifier(identifier, completionHandler: completionHandler)
    }
    
    // MARK: Background Refresh
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        let operation = RefreshLibraryOperation()
//        operation.addObserver(DidFinishObserver { (operation, errors) in
//            guard errors.count == 0 else {
//                completionHandler(.Failed)
//                return
//            }
//            guard let operation = operation as? RefreshLibraryOperation else {
//                completionHandler(.NoData)
//                return
//            }
//            
//            let notification = UILocalNotification()
//            notification.alertTitle = "[DEBUG] Library was refreshed"
//            notification.alertBody = NSDate().description
//            notification.soundName = UILocalNotificationDefaultSoundName
//            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
//            
//            completionHandler(operation.hasUpdate ? .NewData : .NoData)
//        })
//        GlobalQueue.shared.addOperation(operation)
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "self.Kiwix" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Kiwix", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let libDirPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        let libDirURL = URL(fileURLWithPath: libDirPath, isDirectory: true)
        let url = libDirURL.appendingPathComponent("kiwix.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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

