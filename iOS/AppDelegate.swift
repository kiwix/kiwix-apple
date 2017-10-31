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
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: MainController())
        window?.makeKeyAndVisible()
        
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
            try? context.save()
        }
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

extension URL {
    static let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    static let resourceDirectory = Bundle.main.resourceURL!
}
