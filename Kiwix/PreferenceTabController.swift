//
//  PreferenceTabController.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class PreferenceTabController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        tabViewItems[0].label = LocalizedStrings.General
        tabViewItems[1].label = LocalizedStrings.Library
    }
    
}
