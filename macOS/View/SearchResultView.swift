//
//  SearchResultView.swift
//  macOS
//
//  Created by Chris Li on 8/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class SearchTitleSnippetResultTableCellView: NSTableCellView {
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

class SearchTitleResultTableCellView: NSTableCellView {
    @IBOutlet weak var titleField: NSTextField!
}

class SearchFieldContainer: NSView {
    override func awakeFromNib() {
        wantsLayer = true
        layer?.masksToBounds = false
    }
}
