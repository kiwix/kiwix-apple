//
//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa
import RealmSwift
import SwiftyUserDefaults

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // if app crashed previously, do not reopen zim files
        if (!Defaults[.terminated]) {
            Defaults[.zimFilePaths] = []
        }
        Defaults[.terminated] = false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Defaults[.terminated] = true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        guard let controller = NSApplication.shared.mainWindow?.windowController as? Mainv2WindowController,
            let url = URL(string: filename) else {return false}
        controller.openZimFiles(urls: [url])
        return true
    }
}

extension DefaultsKeys {
    static let zimFilePaths = DefaultsKey<[String]>("zimFilePaths", defaultValue: [])
    static let zimFileBookmarks = DefaultsKey<[Data]>("zimFileBookmarks", defaultValue: [])
    static let terminated = DefaultsKey<Bool>("terminated", defaultValue: false)
    static let searchResultExcludeSnippet = DefaultsKey<Bool>("searchResultExcludeSnippet", defaultValue: false)
}

/**
 A trick to make UIImage work on macOS
 */
typealias UIImage = NSImage
extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)

        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }

    convenience init?(named name: String) {
        self.init(named: Name(name))
    }
}
