//
//  IndexerController.swift
//  Kiwix
//
//  Created by Chris Li on 6/3/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class IndexerController: NSViewController {
    
    let indexer = ZimIndexer();

    @IBOutlet weak var zimTextField: NSTextField!
    @IBOutlet weak var indexFolderTextField: NSTextField!
    
    @IBAction func startButtonPushed(sender: NSButton) {
        let zimFileURL = NSURL(fileURLWithPath: zimTextField.stringValue)
        let indexFolderURL = NSURL(fileURLWithPath: zimTextField.stringValue)
        indexer.start(zimFileURL, indexFolderURL: indexFolderURL)
    }
    @IBAction func stopButtonPushed(sender: NSButton) {
//        indexer.stop()
    }
    
}
