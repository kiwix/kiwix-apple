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

import SwiftyUserDefaults
extension DefaultsKeys {
    static let hasShowGetStartedAlert = DefaultsKey<Bool>("hasShowGetStartedAlert")
    static let hasSubscribedToCloudKitChanges = DefaultsKey<Bool>("hasSubscribedToCloudKitChanges")
    static let recentSearchTerms = DefaultsKey<[String]>("recentSearchTerms")
    static let webViewZoomScale = DefaultsKey<Double?>("webViewZoomScale")
    static let activeUseHistory = DefaultsKey<[Date]>("activeUseHistory")
    static let haveRateKiwix = DefaultsKey<Bool>("haveRateKiwix")
    
    static let libraryAutoRefreshDisabled = DefaultsKey<Bool>("libraryAutoRefreshDisabled")
    static let libraryRefreshNotAllowCellularData = DefaultsKey<Bool>("libraryRefreshNotAllowCellularData")
    static let libraryLastRefreshTime = DefaultsKey<Date?>("libraryLastRefreshTime")
    static let libraryRefreshInterval = DefaultsKey<Double?>("libraryRefreshInterval")
    static let preferredLanguageAlertPending = DefaultsKey<Bool>("preferredLanguageAlertPending")
    static let langFilterSortByAlphabeticalAsc = DefaultsKey<Bool>("langFilterSortByAlphabeticalAsc")
    static let langFilterNameDisplayInOriginalLocale = DefaultsKey<Bool>("langFilterNameDisplayInOriginalLocale")
    
    static let resumeData = DefaultsKey<[String: Any]>("resumeData")
}
