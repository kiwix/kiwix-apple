//
//  ViewController.swift
//  Kiwix
//
//  Created by Chris Li on 7/31/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        LibraryRefresher.sharedInstance.fetchBookData()
    }
    

}

