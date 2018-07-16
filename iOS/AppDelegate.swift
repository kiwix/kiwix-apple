//
//  AppDelegate.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryMonitorDelegate {
    var window: UIWindow?
    let fileMonitor = DirectoryMonitor(url: URL.documentDirectory)
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
//        Realm.resetDatabase()
        
        URLProtocol.registerClass(KiwixURLProtocol.self)
        DownloadManager.shared.restorePreviousState()
        application.setMinimumBackgroundFetchInterval(3600 * 24)
        
        fileMonitor.delegate = self
        fileMonitor.start()
        
        if UserDefaults.standard.bool(forKey: "MigratedToRealm") {
            let scan = ScanProcedure(directoryURL: URL.documentDirectory)
            Queue.shared.add(operations: scan)
        } else {
            let scan = ScanProcedure(directoryURL: URL.documentDirectory)
            let migrate = BookmarkMigrationOperation()
            let refresh = LibraryRefreshProcedure()
            migrate.completionBlock = {
                UserDefaults.standard.set(true, forKey: "MigratedToRealm")
            }
            migrate.add(dependency: scan)
            refresh.add(dependency: migrate)
            Queue.shared.add(operations: scan, migrate, refresh)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        updateShortcutItems(application: application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Queue.shared.add(scanProcedure: ScanProcedure(directoryURL: URL.documentDirectory))
        fileMonitor.start()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        fileMonitor.stop()
    }
    
    // MARK: - URL Handling
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme?.caseInsensitiveCompare("kiwix") == .orderedSame else {return false}
        guard let rootNavigationController = window?.rootViewController as? UINavigationController,
            let mainController = rootNavigationController.topViewController as? MainController else {return false}
        mainController.presentedViewController?.dismiss(animated: false)
        mainController.load(url: url)
        return true
    }
    
    // MARK: - State Restoration
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    // MARK: - Directory Monitoring
    
    func directoryContentDidChange(url: URL) {
        Queue.shared.add(scanProcedure: ScanProcedure(directoryURL: url))
    }
    
    // MARK: - Background
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        DownloadManager.shared.backgroundEventsCompleteProcessing = completionHandler
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
    // MARK: - Home Screen Quick Actions
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let rootNavigationController = window?.rootViewController as? UINavigationController,
            let mainController = rootNavigationController.topViewController as? MainController,
            let shortcutItemType = ShortcutItemType(rawValue: shortcutItem.type) else { completionHandler(false); return }
        switch shortcutItemType {
        case .search:
            mainController.shouldShowSearch = true
        case .bookmark:
            mainController.presentedViewController?.dismiss(animated: false)
            mainController.presentAdaptively(controller: mainController.bookmarkController, animated: true)
        case .continueReading:
            break
        }
        completionHandler(true)
    }
    
    private func updateShortcutItems(application: UIApplication) {
        let bookmark = UIApplicationShortcutItem(type: ShortcutItemType.bookmark.rawValue, localizedTitle: NSLocalizedString("Bookmark", comment: "3D Touch Menu Title"))
        let search = UIApplicationShortcutItem(type: ShortcutItemType.search.rawValue, localizedTitle: NSLocalizedString("Search", comment: "3D Touch Menu Title"))
        var shortcutItems = [search, bookmark]
        
        if let rootNavigationController = window?.rootViewController as? UINavigationController,
            let mainController = rootNavigationController.topViewController as? MainController,
            let title = mainController.currentWebController?.currentTitle, let url = mainController.currentWebController?.currentURL {
            shortcutItems.append(UIApplicationShortcutItem(type: ShortcutItemType.continueReading.rawValue,
                                                           localizedTitle: title , localizedSubtitle: NSLocalizedString("Continue Reading", comment: "3D Touch Menu Title"),
                                                           icon: nil, userInfo: ["URL": url.absoluteString]))
        }
        application.shortcutItems = shortcutItems
    }
}

enum ShortcutItemType: String {
    case search, bookmark, continueReading
}

fileprivate extension URL {
    static let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
}
