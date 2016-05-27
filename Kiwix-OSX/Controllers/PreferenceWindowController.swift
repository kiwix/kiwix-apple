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
        
        let frame = CGRectMake(screenRect.width * 0.3, screenRect.height * 0.3, screenRect.width * 0.4, screenRect.height * 0.4)
        
        window.setFrame(frame, display: false)
        
    }
    
}
