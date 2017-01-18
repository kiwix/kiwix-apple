//
//  TableOfContentsController.swift
//  Kiwix
//
//  Created by Chris Li on 6/26/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class TableOfContentsController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    private let visibleHeaderIndicator = UIView()
    
    weak var delegate: TableOfContentsDelegate?
    
    var headings = [HTMLHeading]() {
        didSet {
            configurePreferredContentSize()
            tableView.reloadData()
        }
    }
    
    var visibleRange: (start: Int, length: Int)? {
        didSet {
            configureVisibleHeaderView(animated: true)
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
        visibleHeaderIndicator.backgroundColor = UIColor.red
    }
    
    func configurePreferredContentSize() {
        let count = headings.count
        let width = traitCollection.horizontalSizeClass == .regular ? 300 : (UIScreen.main.bounds.width)
        let height = count == 0 ? 350 : min(CGFloat(count) * 44.0, round(UIScreen.main.bounds.height * 0.65 / 44) * 44)
        preferredContentSize = CGSize(width: width, height: height)
    }
    
    func configureVisibleHeaderView(animated: Bool) {
        // no visible header
        guard let visibleRange = visibleRange else {
            visibleHeaderIndicator.isHidden = true
            return
        }

        let topIndexPath = IndexPath(row: visibleRange.start, section: 0)
        let bottomIndexPath = IndexPath(row: visibleRange.start + visibleRange.length - 1, section: 0)
        let topCellFrame = tableView.rectForRow(at: topIndexPath)
        let bottomCellFrame = tableView.rectForRow(at: bottomIndexPath)
        let top = topCellFrame.origin.y + topCellFrame.height * 0.1
        let bottom = bottomCellFrame.origin.y + bottomCellFrame.height * 0.9

        // indicator frame
        visibleHeaderIndicator.isHidden = false
        if animated {
            UIView.animate(withDuration: 0.1, animations: { 
                self.visibleHeaderIndicator.frame = CGRect(x: 0, y: top, width: 3, height: bottom - top)
            })
        } else {
            visibleHeaderIndicator.frame = CGRect(x: 0, y: top, width: 3, height: bottom - top)
        }

        // tableview scroll
        let topCellVisible = tableView.indexPathsForVisibleRows?.contains(topIndexPath) ?? false
        let bottomCellVisible = tableView.indexPathsForVisibleRows?.contains(bottomIndexPath) ?? false
        switch (topCellVisible, bottomCellVisible) {
        case (true, false):
            tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: animated)
        case (false, true), (false, false):
            tableView.scrollToRow(at: topIndexPath, at: .top, animated: animated)
        default:
            return
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee.y = round(targetContentOffset.pointee.y / 44) * 44
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let heading = headings[indexPath.row]
        switch heading.level {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "H1Cell", for: indexPath)
            cell.textLabel?.text = heading.textContent
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "H2Cell", for: indexPath)
            cell.textLabel?.text = heading.textContent
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = heading.textContent
            cell.indentationLevel = (heading.level - 2) * 2
            return cell
        }
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectHeading(index: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Empty table datasource & delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Compass")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = NSLocalizedString("Table Of Contents Not Available", comment: "Table Of Content, empty text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
}

protocol TableOfContentsDelegate: class {
    func didSelectHeading(index: Int)
}
