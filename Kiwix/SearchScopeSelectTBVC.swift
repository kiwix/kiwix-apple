//
//  SearchScopeSelectTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchScopeSelectTBVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
//        guard let book = fetchedResultController.objectAtIndexPath(indexPath) as? Book else {return}
        guard let cell = cell as? ScopeBookCell else {return}
//
//        cell.titleLabel.text = book.title
//        cell.hasPicIndicator.backgroundColor = (book.isNoPic?.boolValue ?? true) ? UIColor.lightGrayColor() : UIColor.havePicTintColor
//        cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
//        cell.subtitleLabel.text = book.veryDetailedDescription
        
        cell.titleLabel.text = "Wikipedia"
        cell.subtitleLabel.text = "This is a test"
        
    }
 
}
