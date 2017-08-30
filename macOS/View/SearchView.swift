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
//    override func awakeFromNib() {
//        wantsLayer = true
//        layer?.masksToBounds = false
//    }
    
    override func draw(_ dirtyRect: NSRect) {
        wantsLayer = true
        layer?.masksToBounds = false
    }
}

class SearchField: NSSearchField {
    weak var fieldDelegate: SearchFieldDelegate?
    
    private(set) var searchStarted = false {
        didSet {
            if searchStarted {
                placeholderString = prompt
            } else {
                placeholderString = title
            }
        }
    }
    
    var title: String? = "" {
        didSet {
            placeholderString = title ?? prompt
        }
    }
    
    var searchTermCache = ""
    let prompt = "Search"
    
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if !searchStarted {
            stringValue = searchTermCache
            fieldDelegate?.searchWillStart()
            searchStarted = true
        }
    }
    
    func endSearch() {
        if searchStarted {
            stringValue = ""
            fieldDelegate?.searchWillEnd()
            searchStarted = false
        }
    }
}

protocol SearchFieldDelegate: class {
    func searchWillStart()
    func searchWillEnd()
}
