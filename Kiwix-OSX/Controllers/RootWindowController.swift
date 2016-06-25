//
//  RootWindowController.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa
import AppKit

class RootWindowController: NSWindowController {
    
    let searchResultController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("SearchResultController") as? SearchResultController

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window, let screen = window.screen else {return}
        
        window.titleVisibility = .Hidden
        
        let screenRect = screen.visibleFrame
        print(screenRect)
        
        let frame = CGRectMake(screenRect.width * 0.2, screenRect.height * 0.2, screenRect.width * 0.6, screenRect.height * 0.6)
        
        window.setFrame(frame, display: false)
        
    }
    
    func present() {
        searchResultController?.view.frame = NSMakeRect(100, 100, 300, 400)
        let w = NSWindow(contentViewController: searchResultController!)
        window?.addChildWindow(w, ordered: NSWindowOrderingMode.Above)
    }
    
    @IBOutlet weak var searchField: NSSearchField!
    @IBAction func searchFieldTextDidChange(sender: AnyObject) {
        present()
    }
}
