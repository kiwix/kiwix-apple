//
//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris Li on 2/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(notification:)), name: .NSWindowWillClose, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - Window Management
    
    private var windows = [MainWindowController]()

    class func add(controller: MainWindowController) {
        let delegate = NSApplication.shared().delegate as! AppDelegate
        delegate.windows.append(controller)
    }
    
    func windowWillClose(notification: NSNotification) {
        guard let controller = notification.object as? MainWindowController,
            let index = windows.index(of: controller) else {return}
        windows.remove(at: index)
    }
    
    @IBAction func newWindowForTab(_ sender: Any?){}
}

