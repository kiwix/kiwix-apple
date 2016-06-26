//
//  TableOfContentController.swift
//  Kiwix
//
//  Created by Chris Li on 6/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class TableOfContentController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var headings = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configurePreferredContentSize()
    }
    
    func configurePreferredContentSize() {
        let count = headings.count
        preferredContentSize = CGSizeMake(300, count == 0 ? 350 : CGFloat(count) * 44.0)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)


        return cell
    }
 
    
    // MARK: - Empty table datasource & delegate
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Compass")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("Table Of Contents Not Available", comment: "Table Of Content, empty text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
                          NSForegroundColorAttributeName: UIColor.darkGrayColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 0
    }
    
    func spaceHeightForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
}
