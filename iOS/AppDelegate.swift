//
//  AppDelegate.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import Defaults
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryMonitorDelegate {
    var window: UIWindow?
    let fileMonitor = DirectoryMonitor(url: URL.documentDirectory)
    
    // MARK: - Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Realm.Configuration.defaultConfiguration = Realm.defaultConfig
        
        print("Document Directory URL: \(URL.documentDirectory)")
        
        DownloadService.shared.restorePreviousState()
        LibraryService().applyAutoUpdateSetting()
        
        fileMonitor.delegate = self
        fileMonitor.start()
        
        let operation = LibraryScanOperation(url: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(operation)
        
        application.shortcutItems = [
            UIApplicationShortcutItem(type: Shortcut.bookmark.rawValue, localizedTitle: NSLocalizedString("Bookmark", comment: "3D Touch Menu Title")),
            UIApplicationShortcutItem(type: Shortcut.search.rawValue, localizedTitle: NSLocalizedString("Search", comment: "3D Touch Menu Title"))
        ]
        
        Defaults.migrate()

        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        fileMonitor.stop()
    }
    
    // MARK: - Directory Monitoring
    
    func directoryContentDidChange(url: URL) {
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
    }
    
    // MARK: - Background
    
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        DownloadService.shared.backgroundEventsProcessingCompletionHandler = completionHandler
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let operation = OPDSRefreshOperation()
        operation.completionBlock = {
            if operation.error != nil {
                completionHandler(operation.hasUpdates ? .newData : .noData)
            } else {
                completionHandler(.failed)
            }
        }
        LibraryOperationQueue.shared.addOperation(operation)
    }
}

// MARK: - Type Definition

enum Shortcut: String {
    case search, bookmark
}
