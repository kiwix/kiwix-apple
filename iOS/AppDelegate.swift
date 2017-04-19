//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris on 12/11/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import CoreSpotlight
import UserNotifications
import ProcedureKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    class var mainController: MainController {return ((UIApplication.shared.delegate as! AppDelegate)
        .window?.rootViewController as! UINavigationController)
        .topViewController as! MainController}
    
    // MARK: - App State Change
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        URLProtocol.registerClass(KiwixURLProtocol.self)
        _ = Network.shared
        _ = AppNotification.shared
        application.setMinimumBackgroundFetchInterval(86400)
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        ZimMultiReader.shared.startScan()
        UserHabit.shared.appDidBecomeActive()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        func updateQuickActions() {
            let type = "org.kiwix.recent"
            let previousIndex: Int? = {
                guard let recent = UIApplication.shared.shortcutItems?.filter({$0.type == type}).first else {return nil}
                return UIApplication.shared.shortcutItems?.index(of: recent)
            }()
            
            if let index = previousIndex { UIApplication.shared.shortcutItems?.remove(at: index) }
            
            if let article = AppDelegate.mainController.currentTab?.article,
                let title = article.title, let url = article.url?.absoluteString {
                let item = UIMutableApplicationShortcutItem(type: type,
                                                            localizedTitle: title,
                                                            localizedSubtitle: nil,
                                                            icon: UIApplicationShortcutIcon(templateImageName: "Recent"),
                                                            userInfo: ["URL": url])
                if let index = previousIndex {
                    UIApplication.shared.shortcutItems?.insert(item, at: index)
                } else {
                    UIApplication.shared.shortcutItems?.append(item)
                }
            }
        }
        updateQuickActions()
        UserHabit.shared.appWillResignActive()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }
    
    // MARK: - Background
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let refresh = RefreshLibraryProcedure()
        refresh.addDidFinishBlockObserver { (operation, errors) in
            guard Preference.Notifications.libraryRefresh else {return}
            if let _ = errors.first {
                completionHandler(.failed)
            } else {
                OperationQueue.main.addOperation({ 
                    AppNotification.shared.libraryRefreshed(completion: { 
                        completionHandler(operation.hasUpdate ? .newData : .noData)
                    })
                })
            }
        }
        GlobalQueue.shared.add(operation: refresh)
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Network.shared.backgroundEventsCompleteProcessing[identifier] = completionHandler
    }
    
    // MARK: - Quick Actions
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "org.kiwix.search":
            GlobalQueue.shared.add(operation: PresentSearchOperation())
            completionHandler(true)
        case "org.kiwix.bookmarks":
            GlobalQueue.shared.add(operation: PresentBookmarkOperation())
            completionHandler(true)
        case "org.kiwix.recent":
            guard let urlString = shortcutItem.userInfo?["URL"] as? String,
                let url = URL(string: urlString) else {completionHandler(false); return}
            GlobalQueue.shared.add(articleLoad: ArticleLoadOperation(url: url))
            completionHandler(true)
        default:
            completionHandler(false)
            return
        }
    }
    
    // MARK: - Open URL Specified Resource
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        guard url.isKiwixURL else {return false}
        GlobalQueue.shared.add(articleLoad: ArticleLoadOperation(url: url))
        return true
    }
    
    // MARK: - Core Data
    
    lazy var persistentContainer = CoreDataContainer()
    
    class var persistentContainer: CoreDataContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges { try? context.save() }
    }
    
    

    
    
    
    
    // MARK: - Continuity
    
//    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
//        switch userActivity.activityType {
//        case CSSearchableItemActionType:
//            return true
//        default:
//            return false
//        }
//    }
    
//    func registerCloudKit() {
//        if #available(iOS 10, *) {
//            guard !Preference.hasSubscribedToCloudKitChanges else {return}
//            
//            let subscription = CKDatabaseSubscription(subscriptionID: "")
//            let notificationInfo = CKNotificationInfo()
//            notificationInfo.shouldSendContentAvailable = true
//            subscription.notificationInfo = notificationInfo
//            
//            let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
//            operation.modifySubscriptionsCompletionBlock = { savedSubscriptions, _, error in
//                if let error = error {
//                    print(error.localizedDescription)
//                } else {
//                    Preference.hasSubscribedToCloudKitChanges = true
//                }
//            }
//            
//            let database = CKContainer(identifier: "iCloud.org.kiwix").privateCloudDatabase
//            database.add(operation)
//        }
//    }

    
    
    
//    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
//        if userActivity.activityType == "org.kiwix.kiwix.article-view" {
//            guard let navController = window?.rootViewController as? UINavigationController,
//                let controller = navController.topViewController as? MainController else {return false}
//            controller.restoreUserActivityState(userActivity)
//            return true
//        } else {
//            return false
//        }
//    }

}

