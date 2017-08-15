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
        guard let reader = (NSApplication.shared().delegate as? AppDelegate)?.reader,
            let mainPagePath = reader.mainPageURL(),
            let controller = contentViewController as? ViewController,
            let mainPageURL = URL(bookID: reader.getID(), contentPath: mainPagePath) else {return}
        
        print(mainPageURL)
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
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
