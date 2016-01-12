
//
//  TabVC.swift
//  Kiwix
//
//  Created by Chris on 12/21/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class TabVC: UIViewController {

    var tab: Tab?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: false )
    }
    
    func configureView() {
        let searchBar = UISearchBar()
        self.navigationItem.titleView = searchBar
        
        
        if tab?.articles?.count == 0 {
            let localBooksCVC = UIStoryboard.main.instantiateViewControllerWithIdentifier("LocalBooksCVC")
            self.addChildViewController(localBooksCVC)
            self.view.addSubview(localBooksCVC.view)
            localBooksCVC.didMoveToParentViewController(self)
        }
    }
    
    @IBAction func dismissTabButtonTapped(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
