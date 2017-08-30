//
//  WelcomeView.swift
//  macOS
//
//  Created by Chris Li on 8/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class WelcomeView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        NSRectFill(dirtyRect)
        super.draw(dirtyRect)
    }
}
