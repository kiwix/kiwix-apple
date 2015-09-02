//
//  HomePageTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class HomePageTBVC: UITableViewController {
    
    var webViewHomePage = Preference.webViewHomePage
    var webViewHomePageBookID = Preference.webViewHomePageBookID
    var checkedRowIndexPath: NSIndexPath?
    let allLocalBooks: [Book] = {
        var allLocalBooks = Array(ZimMultiReader.sharedInstance.allLocalBooksInDataBase.values)
        allLocalBooks.sortInPlace({ (book1, book2) -> Bool in
            let title1 = book1.title ?? ""
            let title2 = book2.title ?? ""
            return title1.caseInsensitiveCompare(title2) == .OrderedAscending
        })
        return allLocalBooks
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Home Page"
        tableView.tableFooterView = tableFooterView(tableView.frame.width)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.webViewHomePage = webViewHomePage
        Preference.webViewHomePageBookID = webViewHomePageBookID
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.tableFooterView = tableFooterView(size.width)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return allLocalBooks.count > 0 ? 2 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.numberOfSections == 1 {
            return 2
        } else {
            if section == 0 {
                return allLocalBooks.count
            } else {
                return 2
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        // The blank and random cells
        if tableView.numberOfSections == 1 || (tableView.numberOfSections == 2 && indexPath.section == 1) {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Blank"
                cell.accessoryType = webViewHomePage == .Blank ? .Checkmark : .None
            case 1:
                cell.textLabel?.text = "Random"
                cell.accessoryType = webViewHomePage == .Random ? .Checkmark : .None
            default:
                break
            }
        }
        
        // The book cells
        if tableView.numberOfSections == 2 && indexPath.section == 0 {
            if let cell = cell as? BookOrdinaryCell {
                let book = allLocalBooks[indexPath.row]
                cell.favIcon.image = UIImage(data: book.favIcon ?? NSData())
                cell.titleLabel.text = book.title
                cell.subtitleLabel.text = book.detailedDescription
                cell.hasPicIndicator.backgroundColor = book.isNoPic!.boolValue ? UIColor.lightGrayColor() : Utilities.customTintColor()
                cell.accessoryType = (webViewHomePageBookID == book.idString && webViewHomePage == .MainPage) ? .Checkmark : .None
            }
        }
        
        if cell.accessoryType == .Checkmark {
            checkedRowIndexPath = indexPath
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView.numberOfSections == 2 {
            if section == 0 {return "Main Page"}
            if section == 1 {return "Others"}
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let previouslyCheckIndexpath = 
        if let checkedRowIndexPath = checkedRowIndexPath, let cell = tableView.cellForRowAtIndexPath(checkedRowIndexPath) {
            cell.accessoryType = .None
        }
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = .Checkmark
        }
        
        checkedRowIndexPath = indexPath
        
        if tableView.numberOfSections == 1 || (tableView.numberOfSections == 2 && indexPath.section == 1) {
            switch indexPath.row {
            case 0:
                webViewHomePage = .Blank
            case 1:
                webViewHomePage = .Random
            default:
                break
            }
        }
        
        if tableView.numberOfSections == 2 && indexPath.section == 0 {
            let book = allLocalBooks[indexPath.row]
            webViewHomePageBookID = book.idString
            webViewHomePage = .MainPage
        }
    }
    
    func tableFooterView(width: CGFloat) -> UIView {
        let preferredWidth = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? self.navigationController!.preferredContentSize.width : width
        if allLocalBooks.count == 0 {
            return Utilities.tableHeaderFooterView(withMessage: "There are currently no book on device", preferredWidth: preferredWidth, textAlientment: .Center)
        } else {
            return Utilities.tableHeaderFooterView(withMessage: "You may choose the home page here", preferredWidth: preferredWidth, textAlientment: .Center)
        }
    }
}
