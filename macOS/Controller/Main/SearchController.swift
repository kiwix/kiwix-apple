//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class SearchController: NSViewController {
    let searchMenu = NSMenu()
    @IBOutlet weak var searchField: NSSearchField!
    @IBAction func searchFieldChanged(_ sender: NSSearchField) {
        let result = ZimManager.shared.getSearchResults(searchTerm: sender.stringValue)
        print(result)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configSearchMenu()
    }
    
    func configSearchMenu() {
        let clear = NSMenuItem(title: "Clear", action: nil, keyEquivalent: "")
        clear.tag = NSSearchFieldClearRecentsMenuItemTag
        searchMenu.insertItem(clear, at: 0)
        
        searchMenu.insertItem(NSMenuItem.separator(), at: 0)
        
        let recents = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        recents.tag = NSSearchFieldRecentsMenuItemTag
        searchMenu.insertItem(recents, at: 0)
        
        let recentHeader = NSMenuItem(title: "Recent Search", action: nil, keyEquivalent: "")
        recentHeader.tag = NSSearchFieldRecentsTitleMenuItemTag
        searchMenu.insertItem(recentHeader, at: 0)
        
        let noRecent = NSMenuItem(title: "No Recent Search", action: nil, keyEquivalent: "")
        noRecent.tag = NSSearchFieldNoRecentsMenuItemTag
        searchMenu.insertItem(noRecent, at: 0)
        
        searchField.searchMenuTemplate = searchMenu
    }
    
}

//class SearchField: NSSearchField {
//    override func rectForSearchButton(whenCentered isCentered: Bool) -> NSRect {
//        let rect = super.rectForSearchButton(whenCentered: isCentered)
//        return rect.offsetBy(dx: -rect.origin.x, dy: 0)
//    }
//}

