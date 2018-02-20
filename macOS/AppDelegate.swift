//
//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        URLProtocol.registerClass(KiwixURLProtocol.self)
        
        if (!Defaults[.terminated]) {
            Defaults[.bookPaths] = []
        }
        Defaults[.terminated] = false
        
        var isStale = false
        let urls = Defaults[.zimBookmarks].flatMap({try? URL(resolvingBookmarkData: $0, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)}).flatMap({$0})
//        ZimManager.shared.addBook(urls: urls)

        guard let split = NSApplication.shared.mainWindow?.contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        controller.loadMainPage()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Defaults[.terminated] = true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let controller = NSApplication.shared.mainWindow?.windowController as? MainWindowController else {return}
        controller.openBooks(paths: filenames)
    }
}

extension DefaultsKeys {
    static let bookPaths = DefaultsKey<[String]>("bookPaths")
    static let zimBookmarks = DefaultsKey<[Data]>("zimBookmarks")
    static let terminated = DefaultsKey<Bool>("terminated")
}
