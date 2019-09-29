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
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            titleField.textColor = backgroundStyle == .light ? NSColor.black : NSColor.selectedMenuItemTextColor
            let snippetColor = backgroundStyle == .light ? NSColor.labelColor : NSColor.textBackgroundColor
            let snippet = NSMutableAttributedString(attributedString: snippetField.attributedStringValue)
            let range = NSRange(location: 0, length: snippet.length)
            snippet.addAttribute(NSAttributedString.Key.foregroundColor, value: snippetColor, range: range)
            snippetField.attributedStringValue = snippet
        }
    }
}

class SearchTitleResultTableCellView: NSTableCellView {
    @IBOutlet weak var titleField: NSTextField!
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            titleField.textColor = backgroundStyle == .light ? NSColor.black : NSColor.selectedMenuItemTextColor
        }
    }
}

class SearchFieldContainer: NSView {
    override func draw(_ dirtyRect: NSRect) {
        /* We are putting NSSearhField into a plain NSView to get around the NSSearhField in toolbar resizing bug. By removing the view's mask, the search field woun't be clipped. Otherwise, the gray rounded rect border of the NSSearhField will be clipped.
         */
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
    
    override func awakeFromNib() {
        /* Override default cancel button behavior. By default, the search field loses focus when cancel button is clicked. However, in this case, we want the search text to be cleared and keep focus on search field.
         */
        guard let cell = (cell as? NSSearchFieldCell)?.cancelButtonCell else {return}
        cell.target = self
        cell.action = #selector(cancelButtonClicked)
    }
    
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
    
    @objc func cancelButtonClicked() {
        stringValue = ""
        searchTermCache = ""
        fieldDelegate?.searchTextDidClear()
    }
}

protocol SearchFieldDelegate: class {
    func searchWillStart()
    func searchTextDidClear()
    func searchWillEnd()
}
