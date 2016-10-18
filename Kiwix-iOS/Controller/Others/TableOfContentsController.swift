//
//  TableOfContentsController.swift
//  Kiwix
//
//  Created by Chris Li on 6/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class TableOfContentsController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    private let visibleHeaderIndicator = UIView()
    
    weak var delegate: TableOfContentsDelegate?
    private var headinglevelMin = 0
    var articleURL: NSURL?
    
    var headings = [HTMLHeading]() {
        didSet {
            configurePreferredContentSize()
            headinglevelMin = max(2, headings.map({$0.level}).minElement() ?? 0)
            visibleHeaderIDs.removeAll()
            tableView.reloadData()
        }
    }
    var visibleHeaderIDs = [String]() {
        didSet {
            guard oldValue != visibleHeaderIDs else {return}
            configureVisibleHeaderView(animated: oldValue.count > 0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.addSubview(visibleHeaderIndicator)
        visibleHeaderIndicator.backgroundColor = UIColor.redColor()
    }
    
    func configurePreferredContentSize() {
        let count = headings.count
        let width = traitCollection.horizontalSizeClass == .Regular ? 300 : (UIScreen.mainScreen().bounds.width)
        preferredContentSize = CGSizeMake(width, count == 0 ? 350 : min(CGFloat(count) * 44.0, UIScreen.mainScreen().bounds.height * 0.8))
    }
    
    func configureVisibleHeaderView(animated animated: Bool) {
        // no visible header
        guard visibleHeaderIDs.count > 0 else {
            visibleHeaderIndicator.hidden = true
            return
        }
        
        // calculations
        guard let minIndex = headings.indexOf({$0.id == visibleHeaderIDs.first}),
            let maxIndex = headings.indexOf({$0.id == visibleHeaderIDs.last}) else {return}
        let topIndexPath = NSIndexPath(forRow: minIndex, inSection: 0)
        let bottomIndexPath = NSIndexPath(forRow: maxIndex, inSection: 0)
        let topCellFrame = tableView.rectForRowAtIndexPath(topIndexPath)
        let bottomCellFrame = tableView.rectForRowAtIndexPath(bottomIndexPath)
        let top = topCellFrame.origin.y + topCellFrame.height * 0.1
        let bottom = bottomCellFrame.origin.y + bottomCellFrame.height * 0.9
        
        // indicator frame
        visibleHeaderIndicator.hidden = false
        if animated {
            UIView.animateWithDuration(0.1, animations: { 
                self.visibleHeaderIndicator.frame = CGRectMake(0, top, 3, bottom - top)
            })
        } else {
            visibleHeaderIndicator.frame = CGRectMake(0, top, 3, bottom - top)
        }

        // tableview scroll
        let topCellVisible = tableView.indexPathsForVisibleRows?.contains(topIndexPath) ?? false
        let bottomCellVisible = tableView.indexPathsForVisibleRows?.contains(bottomIndexPath) ?? false
        switch (topCellVisible, bottomCellVisible) {
        case (true, false):
            tableView.scrollToRowAtIndexPath(bottomIndexPath, atScrollPosition: .Bottom, animated: animated)
        case (false, true), (false, false):
            tableView.scrollToRowAtIndexPath(topIndexPath, atScrollPosition: .Top, animated: animated)
        default:
            return
        }
    }
    
    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headings.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let heading = headings[indexPath.row]
        switch heading.level {
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("H1Cell", forIndexPath: indexPath)
            cell.textLabel?.text = heading.textContent
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("H2Cell", forIndexPath: indexPath)
            cell.textLabel?.text = heading.textContent
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            cell.textLabel?.text = heading.textContent
            cell.indentationLevel = max(0, (heading.level - headinglevelMin) * 2)
            return cell
        }
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.scrollTo(headings[indexPath.row])
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
        return 0.0
    }
    
    func spaceHeightForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
}

protocol TableOfContentsDelegate: class {
    func scrollTo(heading: HTMLHeading)
}
