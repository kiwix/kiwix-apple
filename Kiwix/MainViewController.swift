//
//  MainViewController.swift
//  Kiwix
//
//  Created by Chris Li on 8/11/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        LibraryRefresher.sharedInstance.refreshLibraryIfNecessary()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowLibrary" {
        }
    }
}
