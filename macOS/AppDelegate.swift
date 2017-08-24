//
//  AppDelegate.swift
//  KiwixMac
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
        ZimManager.shared.addBooks(paths: Defaults[.bookPaths])

        guard let split = NSApplication.shared().mainWindow?.contentViewController as? NSSplitViewController,
            let controller = split.splitViewItems.last?.viewController as? WebViewController else {return}
        controller.loadMainPage()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Defaults[.terminated] = true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension DefaultsKeys {
    static let bookPaths = DefaultsKey<[String]>("bookPaths")
    static let terminated = DefaultsKey<Bool>("terminated")
}
