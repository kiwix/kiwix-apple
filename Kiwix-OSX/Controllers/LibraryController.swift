//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa
import CoreData

class LibraryController: NSViewController {
    
    @IBOutlet weak var refresh: NSButton!
    @IBAction func refresh(sender: NSButton) {
        let operation = RefreshLibraryOperation(invokedAutomatically: false, completionHandler: nil)
        GlobalOperationQueue.sharedInstance.addOperation(operation)
    }
    let managedObjectContext = NSApplication.appDelegate.managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = LocalizedStrings.Library
    }
    
}
