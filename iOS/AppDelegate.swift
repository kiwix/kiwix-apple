//
//  AppDelegate.swift
//  WikiMed
//
//  Created by Chris Li on 9/6/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: MainController())
        window?.makeKeyAndVisible()
        
        URLProtocol.registerClass(KiwixURLProtocol.self)
        ZimMultiReader.shared.startMonitoring(url: URL.documentDirectory)
        ZimMultiReader.shared.scan(url: URL.documentDirectory)
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        ZimMultiReader.shared.startMonitoring(url: URL.documentDirectory)
        ZimMultiReader.shared.scan(url: URL.documentDirectory)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        ZimMultiReader.shared.stopMonitoring(url: URL.documentDirectory)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        let context = CoreDataContainer.shared.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }
}

extension URL {
    static let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    static let resourceDirectory = Bundle.main.resourceURL!
}
