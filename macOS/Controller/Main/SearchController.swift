//
//  SearchController.swift
//  macOS
//
//  Created by Chris Li on 8/22/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import Cocoa

class SearchController: NSViewController {
    @IBOutlet weak var searchField: NSSearchField!
    @IBAction func searchFieldChanged(_ sender: NSSearchField) {
        print(sender.stringValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
