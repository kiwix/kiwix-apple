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
        if #available(iOS 13.0, *) {} else {
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = RootController()
            window?.makeKeyAndVisible()
        }
        
        print(URL.documentDirectory)
        
        DownloadManager.shared.restorePreviousState()
        application.setMinimumBackgroundFetchInterval(3600 * 24)
        
        fileMonitor.delegate = self
        fileMonitor.start()
        
        let operation = LibraryScanOperation(url: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(operation)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        updateShortcutItems(application: application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
        fileMonitor.start()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        fileMonitor.stop()
    }
    
    // MARK: - URL Handling
    
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let rootController = window?.rootViewController as? RootController else {return false}
        rootController.dismiss(animated: false)
        if url.scheme?.caseInsensitiveCompare("kiwix") == .orderedSame {
            rootController.contentViewController.load(url: url)
            return true
        } else if url.scheme == "file" {
            if let _ = ZimMultiReader.getMetaData(url: url) {
                let canOpenInPlace = options[.openInPlace] as? Bool ?? false
                let fileImportController = FileImportController(fileURL: url, canOpenInPlace: canOpenInPlace)
                rootController.present(fileImportController, animated: true)
            } else {
                rootController.present(FileImportAlertController(fileName: url.lastPathComponent), animated: true)
            }
            return true
        } else {
            return false
        }
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
        let scan = LibraryScanOperation(directoryURL: URL.documentDirectory)
        LibraryOperationQueue.shared.addOperation(scan)
    }
    
    // MARK: - Background
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        DownloadManager.shared.backgroundEventsCompleteProcessing = completionHandler
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let operation = LibraryRefreshOperation(updateExisting: false)
        operation.completionBlock = {
            if operation.error != nil {
                completionHandler(operation.hasUpdates ? .newData : .noData)
            } else {
                completionHandler(.failed)
            }
        }
        LibraryOperationQueue.shared.addOperation(operation)
    }
    
    // MARK: - Home Screen Quick Actions
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let rootController = window?.rootViewController as? RootController,
            let shortcutItemType = ShortcutItemType(rawValue: shortcutItem.type) else { completionHandler(false); return }
        switch shortcutItemType {
        case .search:
            rootController.contentViewController.searchController.isActive = true
        case .bookmark:
            rootController.dismiss(animated: false)
            rootController.contentViewController.openBookmark()
        case .continueReading:
            break
        }
        completionHandler(true)
    }
    
    private func updateShortcutItems(application: UIApplication) {
        let bookmark = UIApplicationShortcutItem(type: ShortcutItemType.bookmark.rawValue, localizedTitle: NSLocalizedString("Bookmark", comment: "3D Touch Menu Title"))
        let search = UIApplicationShortcutItem(type: ShortcutItemType.search.rawValue, localizedTitle: NSLocalizedString("Search", comment: "3D Touch Menu Title"))
        var shortcutItems = [search, bookmark]
        
        if let rootController = window?.rootViewController as? RootController,
            let title = rootController.contentViewController.webViewController.title,
            let url = rootController.contentViewController.webViewController.currentURL {
            shortcutItems.append(UIApplicationShortcutItem(type: ShortcutItemType.continueReading.rawValue,
            localizedTitle: title , localizedSubtitle: NSLocalizedString("Continue Reading", comment: "3D Touch Menu Title"),
            icon: nil, userInfo: ["URL": url.absoluteString as NSSecureCoding]))
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
