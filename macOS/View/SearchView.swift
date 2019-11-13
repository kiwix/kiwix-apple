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

class SearchField: NSSearchField, NSSearchFieldDelegate {
    weak var eventDelegate: SearchFieldEvent?
//    private var searchTermCache = ""
//    private let prompt = "Search"
    
    private(set) var searchStarted = false {
        didSet {
            if searchStarted {
//                placeholderString = prompt
            } else {
//                placeholderString = title
            }
        }
    }
    
    var title: String? = "" {
        didSet {
//            placeholderString = title ?? prompt
        }
    }
    
    override func awakeFromNib() {
        self.delegate = self
        self.target = self
        self.action = #selector(searchFieldTextDidChange)
        if let cell = (cell as? NSSearchFieldCell)?.cancelButtonCell {
            cell.target = self
            cell.action = #selector(cancelButtonClicked)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if !searchStarted {
//            stringValue = searchTermCache
            eventDelegate?.searchWillStart(searchField: self)
            searchStarted = true
        }
    }
    
    func endSearch() {
        guard searchStarted else {return}
        stringValue = ""
        eventDelegate?.searchWillEnd(searchField: self)
        searchStarted = false
    }
    
    @objc func searchFieldTextDidChange(_ sender: NSSearchField) {
//        searchTermCache = sender.stringValue
        self.eventDelegate?.searchTextDidChange(searchField: self)
    }
    
    @objc func cancelButtonClicked() {
        stringValue = ""
//        searchTermCache = ""
        eventDelegate?.searchTextDidClear(searchField: self)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let searchField = obj.object as? NSSearchField, searchField == self else {return}
        // when enter key is pressed, currently do nothing
    }
}

protocol SearchFieldEvent: class {
    func searchWillStart(searchField: NSSearchField)
    func searchTextDidChange(searchField: NSSearchField)
    func searchTextDidClear(searchField: NSSearchField)
    func searchWillEnd(searchField: NSSearchField)
}
