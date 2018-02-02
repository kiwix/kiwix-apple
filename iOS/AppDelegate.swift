//
//  AppDelegate.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DirectoryMonitorDelegate {
    var window: UIWindow?
    let monitor = DirectoryMonitor(url: URL.documentDirectory)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Network.shared.restorePreviousState()
        URLProtocol.registerClass(KiwixURLProtocol.self)
        monitor.delegate = self
        Queue.shared.add(scanProcedure: ScanProcedure(url: URL.documentDirectory))
        monitor.start()
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Queue.shared.add(scanProcedure: ScanProcedure(url: URL.documentDirectory))
        monitor.start()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        monitor.stop()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        let context = CoreDataContainer.shared.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print(error)
            }
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
        Queue.shared.add(scanProcedure: ScanProcedure(url: url))
    }
    
    // MARK: - Background
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Network.shared.backgroundEventsCompleteProcessing = completionHandler
    }
}

fileprivate extension URL {
    static let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
}
