//
//  PreferenceLibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class PreferenceLibraryController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = LocalizedStrings.Library
    }
    
}
