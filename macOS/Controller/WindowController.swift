//
//  WindowController.swift
//  KiwixMac
//
//  Created by Chris Li on 8/15/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    @IBAction func mainButtonTapped(_ sender: NSToolbarItem) {
        guard let id = ZimManager.shared.getReaderIDs().first,
            let mainPagePath = ZimManager.shared.getMainPagePath(bookID: id),
            let controller = contentViewController as? ViewController,
            let mainPageURL = URL(bookID: id, contentPath: mainPagePath) else {return}
        let request = URLRequest(url: mainPageURL)
        controller.webView.mainFrame.load(request)
    }
    
    @IBAction func backButtonClicked(_ sender: NSToolbarItem) {
        guard let controller = contentViewController as? ViewController else {return}
        print(controller.webView.canGoBack)
        controller.webView.goBack()
    }
    
    @IBAction func forwardButtonClicked(_ sender: NSToolbarItem) {
        guard let controller = contentViewController as? ViewController else {return}
        controller.webView.goForward()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "Kiwix"
    }
}
