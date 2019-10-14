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
class AppDelegate: NSObject, NSApplicationDelegate, TabManagement {
    private let queue = OperationQueue()
    private var windowControllers = Set<NSWindowController>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // if app crashed previously, do not reopen zim files
        if (!Defaults[.terminated]) {
            Defaults[.zimFilePaths] = []
        }
        Defaults[.terminated] = false
        
        // scan zim files
        queue.addOperation(LibraryScanOperation())
        
        // set up initial window controller
        if let windowController = NSApplication.shared.mainWindow?.windowController as? WindowController {
            windowControllers.insert(windowController)
            windowController.tabManager = self
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Defaults[.terminated] = true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        guard let url = URL(string: filename) else {return false}
        openFile(urls: [url])
        return true
    }
    
    // MARK: - TabManagment
    
    func createTab(window: NSWindow) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialController() as! WindowController
        windowControllers.insert(controller)
        controller.tabManager = self
        window.addTabbedWindow(controller.window!, ordered: .above)
        controller.window?.makeKeyAndOrderFront(nil)
    }
    
    func willCloseTab(controller: NSWindowController) {
        windowControllers.remove(controller)
    }
    
    // MARK: - open file
    
    func openFile(urls: [URL]) {
        let operation = LibraryScanOperation(urls: urls)
        queue.addOperation(operation)
    }
}

protocol TabManagement: class {
    func createTab(window: NSWindow)
    func willCloseTab(controller: NSWindowController)
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
