//
//  BookDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookDetailController: UITableViewController {
    
    @IBOutlet weak var favIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasPicLabel: UILabel!
    @IBOutlet weak var hasIndexIndicator: UILabel!
    @IBOutlet weak var hasIndexLabel: UILabel!
    
    var book: Book?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureViews()
    }
    
    func configureViews() {
        guard let book = book else {return}
        
        title = book.title
        favIconImageView.image = UIImage(data: book.favIcon ?? NSData())
        titleLabel.text = book.title
        
        hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGrayColor()
        hasPicLabel.text = book.hasPic ? LocalizedStrings.BookDetail.hasPic : LocalizedStrings.BookDetail.noPic
        hasIndexIndicator.backgroundColor = book.hasIndex ? AppColors.hasIndexTintColor : UIColor.lightGrayColor()
        hasIndexLabel.text = book.hasIndex ? LocalizedStrings.BookDetail.hasIndex : LocalizedStrings.BookDetail.noIndex
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 3
        case 2: return 2
        case 3: return 1
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Download Now", comment: LocalizedStrings.BookDetail.comment)
            cell.textLabel?.textColor = UIColor.blueColor()
            return cell
        case (0, 1):
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Schedule Download", comment: LocalizedStrings.BookDetail.comment)
            cell.textLabel?.textColor = UIColor.blueColor()
            return cell
        case (0,2):
            let cell = tableView.dequeueReusableCellWithIdentifier("TextSwitchCell", forIndexPath: indexPath) as! TextSwitchCell
            cell.titleLabel.text = NSLocalizedString("Download Updates Automatically", comment: LocalizedStrings.BookDetail.comment)
            return cell
        case (1, 0):
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Size", comment: LocalizedStrings.BookDetail.comment)
            cell.detailTextLabel?.text = book?.fileSizeFormatted
            return cell
        case (1, 1):
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Creation Date", comment: LocalizedStrings.BookDetail.comment)
            cell.detailTextLabel?.text = book?.dateFormatted
            return cell
        case (1, 2):
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Article Count", comment: LocalizedStrings.BookDetail.comment)
            cell.detailTextLabel?.text = book?.articleCountFormatted
            return cell
        case (2, 0):
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Creator", comment: LocalizedStrings.BookDetail.comment)
            cell.detailTextLabel?.text = book?.creator
            return cell
        case (2, 1):
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = NSLocalizedString("Publisher", comment: LocalizedStrings.BookDetail.comment)
            cell.detailTextLabel?.text = book?.publisher
            return cell
        case (3, 0):
            let cell = tableView.dequeueReusableCellWithIdentifier("DescCell", forIndexPath: indexPath)
            cell.textLabel?.text = book?.desc
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 3 else {return nil}
        return NSLocalizedString("Description", comment: LocalizedStrings.BookDetail.comment)
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {return 25.0}
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
}

extension LocalizedStrings {
    class BookDetail {
        private static let comment = "Library, Book Detail"
        static let hasIndex = NSLocalizedString("Index", comment: comment)
        static let hasPic = NSLocalizedString("Pictures", comment: comment)
        static let noIndex = NSLocalizedString("No Index", comment: comment)
        static let noPic = NSLocalizedString("No Picture", comment: comment)
        
//        static let noPic = NSLocalizedString("No Picture", comment: comment)
    }
}
