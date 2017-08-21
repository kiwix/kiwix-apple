//
//  AppDelegate.swift
//  KiwixMac
//
//  Created by Chris Li on 8/14/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        URLProtocol.registerClass(KiwixURLProtocol.self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
