//
//  BookDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class BookDetailController: UITableViewController, CenterButtonCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var favIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasPicLabel: UILabel!
    @IBOutlet weak var hasIndexIndicator: UILabel!
    @IBOutlet weak var hasIndexLabel: UILabel!
    
    typealias Strings = LocalizedStrings.BookDetail
    
    var book: Book?
    var cellTitles = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
        
        configureViews()
    }
    
    func configureViews() {
        guard let book = book else {return}
        
        // Config static UI
        title = book.title
        favIconImageView.image = UIImage(data: book.favIcon ?? NSData())
        titleLabel.text = book.title
        
        hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGrayColor()
        hasPicLabel.text = book.hasPic ? LocalizedStrings.BookDetail.hasPic : LocalizedStrings.BookDetail.noPic
        hasIndexIndicator.backgroundColor = book.hasIndex ? AppColors.hasIndexTintColor : UIColor.lightGrayColor()
        hasIndexLabel.text = book.hasIndex ? LocalizedStrings.BookDetail.hasIndex : LocalizedStrings.BookDetail.noIndex
        
        titleLabel.hidden = false
        hasPicIndicator.hidden = false
        hasPicLabel.hidden = false
        hasIndexIndicator.hidden = false
        hasIndexLabel.hidden = false
        
        // Generate table structure
        cellTitles.append([String]())
        if book.isLocal?.boolValue == false {
            if book.spaceState == .NotEnough {
                cellTitles.append([Strings.spaceNotEnough])
            } else {
                cellTitles.append([Strings.downloadNow])
            }
        } else {
            cellTitles.append([Strings.remove])
        }
        cellTitles.append([Strings.size, Strings.createDate, Strings.arcitleCount, Strings.language, Strings.creator, Strings.publisher])
    }
    
    // MARK: - Delegates
    
    func buttonTapped(cell: CenterButtonCell) {
        guard let title = cell.button.titleLabel?.text,
            let book = book else {return}
        
        switch title {
        case Strings.downloadNow:
            func startDownload() {
                guard let bookID = book.id,
                    let download = DownloadBookOperation(bookID: bookID) else {return}
                Network.shared.queue.addOperation(download)
            }
            
            if book.spaceState == .Caution {
                let cancel = UIAlertAction(title: Strings.cancel, style: .Cancel, handler: nil)
                let download = UIAlertAction(title: Strings.SpaceAlert.downloadAnyway, style: .Destructive, handler: { (alert) in
                    startDownload()
                })
                let alertController = UIAlertController(title: Strings.SpaceAlert.spaceAlert, message: Strings.SpaceAlert.message, actions: [download, cancel])
                presentViewController(alertController, animated: true, completion: nil)
            } else {
                startDownload()
            }
       default:
            return
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return cellTitles.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let title = cellTitles[indexPath.section][indexPath.row]
        switch title {
        case Strings.downloadNow, Strings.spaceNotEnough, Strings.remove:
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterButtonCell", forIndexPath: indexPath) as! CenterButtonCell
            cell.button.setTitle(title, forState: .Normal)
            cell.delegate = self
            
            switch title {
            case Strings.spaceNotEnough:
                cell.button.tintColor = UIColor.grayColor()
            case Strings.remove:
                cell.button.tintColor = UIColor.redColor()
            default:
                if book?.spaceState == .Caution { cell.button.tintColor = UIColor.orangeColor() }
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = title
            switch title {
            case Strings.size:
                cell.detailTextLabel?.text = book?.fileSizeDescription
            case Strings.createDate:
                cell.detailTextLabel?.text = book?.dateDescription
            case Strings.arcitleCount:
                cell.detailTextLabel?.text = book?.articleCountString
            case Strings.language:
                cell.detailTextLabel?.text = book?.language?.nameInCurrentLocale
            case Strings.creator:
                cell.detailTextLabel?.text = book?.creator
            case Strings.publisher:
                cell.detailTextLabel?.text = book?.publisher
            default:
                break
            }
            return cell
}

//        case (0,2):
//            let cell = tableView.dequeueReusableCellWithIdentifier("TextSwitchCell", forIndexPath: indexPath) as! TextSwitchCell
//            cell.titleLabel.text = NSLocalizedString("Updates Automatically", comment: LocalizedStrings.BookDetail.comment)
//            return cell

    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return Strings.download
        case 2:
            return Strings.bookInfo
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return book?.desc
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView where section == 0 else {return}
        view.textLabel?.textAlignment = .Center
    }
}

extension LocalizedStrings {
    class BookDetail {
        private static let comment = "Library, Book Detail"
        static let hasIndex = NSLocalizedString("Index", comment: comment)
        static let hasPic = NSLocalizedString("Pictures", comment: comment)
        static let noIndex = NSLocalizedString("No Index", comment: comment)
        static let noPic = NSLocalizedString("No Picture", comment: comment)
        
        static let download = NSLocalizedString("Download", comment: comment)
        static let bookInfo = NSLocalizedString("Book Info", comment: comment)
        
        static let downloadNow = NSLocalizedString("Download Now", comment: comment)
        static let spaceNotEnough = NSLocalizedString("Space Not Enough", comment: comment)
        static let pause = NSLocalizedString("Pause", comment: comment)
        static let cancel = NSLocalizedString("Cancel", comment: comment)
        static let remove = NSLocalizedString("Remove", comment: comment)
        
        static let size = NSLocalizedString("Size", comment: comment)
        static let createDate = NSLocalizedString("Creation Date", comment: comment)
        static let arcitleCount = NSLocalizedString("Article Count", comment: comment)
        static let language = NSLocalizedString("Language", comment: comment)
        static let creator = NSLocalizedString("Creator", comment: comment)
        static let publisher = NSLocalizedString("Publisher", comment: comment)
        
        class SpaceAlert {
            private static let comment = "Library, Book Detail, Space Alert"
            static let downloadAnyway = NSLocalizedString("Download Anyway", comment: comment)
            static let spaceAlert = NSLocalizedString("Space Alert", comment: comment)
            static let message = NSLocalizedString("This book will take up more than 80% of your free space after downloaded", comment: comment)
        }
    }
}
