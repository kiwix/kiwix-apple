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
        print(path)
        
        let url = URL(fileURLWithPath: path)
        
        (NSApplication.shared().delegate as! AppDelegate).reader = ZimReader(zimFileURL: url)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
