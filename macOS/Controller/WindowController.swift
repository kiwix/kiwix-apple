//
//  WindowController.swift
//  KiwixMac
//
//  Created by Chris Li on 8/15/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    @IBAction func mainPageButtonTapped(_ sender: NSToolbarItem) {
        guard let id = ZimManager.shared.getReaderIDs().first,
            let mainPagePath = ZimManager.shared.getMainPagePath(bookID: id),
            let controller = contentViewController as? ViewController,
            let mainPageURL = URL(bookID: id, contentPath: mainPagePath) else {return}
        let request = URLRequest(url: mainPageURL)
        controller.webView.mainFrame.load(request)
    }
    
    @IBAction func backForwardControlClicked(_ sender: NSSegmentedControl) {
        guard let controller = contentViewController as? ViewController else {return}
        if sender.selectedSegment == 0 {
            controller.webView.goBack()
        } else if sender.selectedSegment == 1 {
            controller.webView.goForward()
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.title = "Kiwix"
    }
}
