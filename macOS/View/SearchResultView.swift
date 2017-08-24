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
            titleField.textColor = backgroundStyle == .light ? NSColor.black : NSColor.selectedMenuItemTextColor
            let snippetColor = backgroundStyle == .light ? NSColor.labelColor : NSColor.textBackgroundColor
            let snippet = NSMutableAttributedString(attributedString: snippetField.attributedStringValue)
            let range = NSRange(location: 0, length: snippet.length)
            snippet.addAttribute(NSForegroundColorAttributeName, value: snippetColor, range: range)
            snippetField.attributedStringValue = snippet
        }
    }
}

class SearchResultTableRowView: NSTableRowView {
//    override func drawSeparator(in dirtyRect: NSRect) {
//        Swift.print(dirtyRect)
//        Swift.print(NSRect(x: 8, y: 0, width: dirtyRect.width - 8, height: dirtyRect.height))
//        super.drawBackground(in: dirtyRect.insetBy(dx: 8, dy: 8))
//    }
}
