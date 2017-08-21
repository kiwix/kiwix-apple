//
//  OpenController.swift
//  KiwixMac
//
//  Created by Chris Li on 8/15/17.
//  Copyright © 2017 Kiwix. All rights reserved.
//

import Cocoa

class OpenController: NSViewController {
    @IBOutlet weak var pathTextField: NSTextField!

    @IBAction func openButtonTapped(_ sender: NSButton) {
        let path = pathTextField.stringValue
        ZimManager.shared.addBook(path: path)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
