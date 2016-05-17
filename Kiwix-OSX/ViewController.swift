//
//  ViewController.swift
//  Kiwix-OSX
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = NSURL(fileURLWithPath: "/Volumes/Data/ZIM Files/wikipedia_en_simple_all_2015-10.zim")
        let reader = ZimReader(ZIMFileURL: url)
        print(reader.getID())
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

