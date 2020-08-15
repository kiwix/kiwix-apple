//
//  SearchResultView.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 8/23/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class SearchResultCell: NSTableCellView {
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var snippetField: NSTextField!
}

class SearchField: NSSearchField, NSSearchFieldDelegate {
    weak var eventDelegate: SearchFieldEvent?
    private(set) var searchStarted = false
    
    override func awakeFromNib() {
        self.delegate = self
        self.target = self
        self.action = #selector(searchFieldTextDidChange)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if !searchStarted {
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
        self.eventDelegate?.searchTextDidChange(searchField: self)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let searchField = obj.object as? NSSearchField, searchField == self else {return}
        // when enter key is pressed, currently do nothing
    }
}

protocol SearchFieldEvent: class {
    func searchWillStart(searchField: NSSearchField)
    func searchTextDidChange(searchField: NSSearchField)
    func searchWillEnd(searchField: NSSearchField)
}
