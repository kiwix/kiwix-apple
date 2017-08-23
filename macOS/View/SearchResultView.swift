//
//  SearchResultView.swift
//  macOS
//
//  Created by Chris Li on 8/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class SearchResultTableCellView: NSTableCellView {
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var snippetField: NSTextField!
    
    override var backgroundStyle: NSBackgroundStyle {
        didSet {
            if backgroundStyle == .light {
                titleField.textColor = NSColor.black
                snippetField.textColor = NSColor.labelColor
            } else {
                titleField.textColor = NSColor.selectedMenuItemTextColor
                snippetField.textColor = NSColor.selectedTextBackgroundColor
            }
        }
    }
}

class SearchResultTableRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        super.drawSelection(in: dirtyRect)
        if isSelected {
        }
    }

    
//    override func drawSeparator(in dirtyRect: NSRect) {
//        Swift.print(dirtyRect)
//        Swift.print(NSRect(x: 8, y: 0, width: dirtyRect.width - 8, height: dirtyRect.height))
//        super.drawBackground(in: dirtyRect.insetBy(dx: 8, dy: 8))
//    }
}
