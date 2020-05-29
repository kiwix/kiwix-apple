//
//  AppDelegate.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa
import Defaults
import RealmSwift

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
    
    func createTab(window: NSWindow) -> WindowController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateInitialController() as! WindowController
        windowControllers.insert(controller)
        controller.tabManager = self
        window.addTabbedWindow(controller.window!, ordered: .above)
        controller.window?.makeKeyAndOrderFront(nil)
        return controller
    }
    
    func willCloseTab(controller: NSWindowController) {
        windowControllers.remove(controller)
    }
    
    // MARK: - open file
    
    func openFile(urls: [URL]) {
        let operation = LibraryScanOperation(urls: urls)
        operation.completionBlock = {
            DispatchQueue.main.sync {
                guard let keyWindow = NSApplication.shared.keyWindow else {return}
                for url in urls {
                    guard let meta = ZimMultiReader.getMetaData(url: url),
                        let id = meta["id"] as? String,
                        let mainPageURL = ZimMultiReader.shared.getMainPageURL(zimFileID: id) else {continue}
                
                    /*
                     Decide which window should show the main page of the newly opened zim file.
                     If the current window is showing the welcome window, use current window; otherwise create a new window.
                     */
                    let windowController: WindowController = {
                        if let windowController = NSApplication.shared.mainWindow?.windowController as? WindowController,
                            let mode = windowController.contentTabController?.mode, mode == .welcome {
                            return windowController
                        } else {
                            return self.createTab(window: keyWindow)
                        }
                    }()
                    windowController.contentTabController?.setMode(.reader)
                    windowController.webViewController?.load(url: mainPageURL)
                }
            }
        }
        queue.addOperation(operation)
    }
}

protocol TabManagement: class {
    func createTab(window: NSWindow) -> WindowController
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
