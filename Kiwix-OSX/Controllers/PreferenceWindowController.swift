//
//  PreferenceWindowController.swift
//  Kiwix
//
//  Created by Chris Li on 5/18/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class PreferenceWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window, let screen = window.screen else {return}
        
        let screenRect = screen.visibleFrame
        print(screenRect)
        
        let frame = CGRectMake(screenRect.width * 0.25, screenRect.height * 0.25, screenRect.width * 0.5, screenRect.height * 0.5)
        
        window.setFrame(frame, display: false)
        
    }
    
}
