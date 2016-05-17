//
//  RootWindowController.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class RootWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window, let screen = window.screen else {return}
        
        let screenRect = screen.visibleFrame
        print(screenRect)
        
        let frame = CGRectMake(screenRect.width * 0.2, screenRect.height * 0.2, screenRect.width * 0.6, screenRect.height * 0.6)
        
        window.setFrame(frame, display: false)
        
    }

}
