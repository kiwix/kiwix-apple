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
        
        // if app crashed previously, do not reopen zim files
        if (!Defaults[.terminated]) {
            Defaults[.zimFilePaths] = []
        }
        Defaults[.terminated] = false
        
        let urls = Defaults[.zimFileBookmarks].compactMap { (data) -> URL? in
            var isStale = false
            let url = (((try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)) as URL??)) ?? nil
            return isStale ? nil : url
        }
        urls.forEach({ ZimMultiReader.shared.add(url: $0)})

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
        controller.openZimFiles(paths: filenames)
    }
}

extension DefaultsKeys {
    static let zimFilePaths = DefaultsKey<[String]>("zimFilePaths", defaultValue: [])
    static let zimFileBookmarks = DefaultsKey<[Data]>("zimFileBookmarks", defaultValue: [])
    static let terminated = DefaultsKey<Bool>("terminated", defaultValue: false)
    static let searchResultExcludeSnippet = DefaultsKey<Bool>("searchResultExcludeSnippet", defaultValue: false)
}
