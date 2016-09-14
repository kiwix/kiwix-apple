//
//  BookDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class BookDetailController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var favIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasPicLabel: UILabel!
    @IBOutlet weak var hasIndexIndicator: UILabel!
    @IBOutlet weak var hasIndexLabel: UILabel!
    
    var context: UnsafeMutablePointer<Void> = nil
    typealias Strings = LocalizedStrings.BookDetail
    
    var book: Book?
    var sectionHeaders = [String?]()
    var sectionFooters = [String?]()
    var cellTitles = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureViews()
        book?.addObserver(self, forKeyPath: "isLocal", options: .New, context: context)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        book?.removeObserver(self, forKeyPath: "isLocal", context: context)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let book = object as? Book where context == self.context else {return}
        NSOperationQueue.mainQueue().addOperationWithBlock {
            print(book.isLocal)
            self.configureActionSection(book)
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Fade)
        }
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
        // Book desc
        sectionHeaders.append(nil)
        sectionFooters.append(book.desc)
        cellTitles.append([String]())
        
        // Action Cells
        sectionHeaders.append(nil)
        sectionFooters.append(nil)
        cellTitles.append([])
        configureActionSection(book)
        
        // Book Info
        sectionHeaders.append(Strings.bookInfo)
        sectionFooters.append(nil)
        cellTitles.append([Strings.size, Strings.createDate, Strings.arcitleCount, Strings.language, Strings.creator, Strings.publisher])
        
        // PID
        if let _ = book.pid {
            sectionHeaders.append(Strings.pid)
            sectionFooters.append(Strings.pidNote)
            cellTitles.append([Strings.pid])
        }
        
        // URL
        if let _ = book.url {
            sectionHeaders.append(nil)
            sectionFooters.append(nil)
            cellTitles.append([Strings.copyURL])
        }
        
        tableView.reloadEmptyDataSet()
    }
    
    func configureActionSection(book: Book) {
        if let isLocal = book.isLocal?.boolValue {
            if isLocal {
                cellTitles[1] = [Strings.remove]
            } else {
                cellTitles[1] = book.spaceState == .NotEnough ? [Strings.spaceNotEnough] : [Strings.downloadNow]
            }
        } else {
            cellTitles[1] = [Strings.cancel]
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
        case Strings.downloadNow, Strings.spaceNotEnough, Strings.cancel, Strings.remove:
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = title
            
            switch title {
            case Strings.downloadNow:
                if book?.spaceState == .Caution {cell.textLabel?.textColor = UIColor.orangeColor()}
            case Strings.spaceNotEnough:
                cell.textLabel?.textColor = UIColor.grayColor()
            case Strings.cancel, Strings.remove:
                cell.textLabel?.textColor = UIColor.redColor()
            default:
                break
            }
            return cell
        case Strings.pid:
            let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
            cell.textLabel?.text = book?.pid
            return cell
        case Strings.copyURL:
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = title
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
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionFooters[section]
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView where section == 0 else {return}
        view.textLabel?.textAlignment = .Center
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let cell = tableView.cellForRowAtIndexPath(indexPath),
            let title = cell.textLabel?.text,
            let book = book else {return}
        switch title {
        case Strings.downloadNow:
            func startDownload() {
                guard let download = DownloadBookOperation(bookID: book.id) else {return}
                Network.shared.queue.addOperation(download)
            }
            
            if book.spaceState == .Caution {
                let cancel = UIAlertAction(title: Strings.cancel, style: .Cancel, handler: nil)
                let download = UIAlertAction(title: Strings.SpaceAlert.downloadAnyway, style: .Destructive, handler: { (alert) in
                    startDownload()
                })
                let alertController = UIAlertController(title: Strings.SpaceAlert.spaceAlert, message: Strings.SpaceAlert.message, preferredStyle: .Alert)
                [download, cancel].forEach({ alertController.addAction($0) })
                presentViewController(alertController, animated: true, completion: nil)
            } else {
                startDownload()
            }
            
        case Strings.copyURL:
            guard let url = book.url else {return}
            UIPasteboard.generalPasteboard().string = url.absoluteString
            let action = UIAlertAction(title: LocalizedStrings.Common.ok, style: .Cancel, handler: nil)
            let alertController = UIAlertController(title: Strings.CopyURLAlert.succeed, message: nil, preferredStyle: .Alert)
            alertController.addAction(action)
            presentViewController(alertController, animated: true, completion: nil)
        default:
            return
        }
    }
}

extension LocalizedStrings {
    class BookDetail {
        private static let comment = "Library, Book Detail"
        static let hasIndex = NSLocalizedString("Index", comment: comment)
        static let hasPic = NSLocalizedString("Pictures", comment: comment)
        static let noIndex = NSLocalizedString("No Index", comment: comment)
        static let noPic = NSLocalizedString("No Picture", comment: comment)
        
        static let pid = NSLocalizedString("Persistent ID", comment: comment)
        static let bookInfo = NSLocalizedString("Book Info", comment: comment)
        
        static let pidNote = NSLocalizedString("This ID does not change in different versions of the same book.", comment: comment)
        
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
        
        static let copyURL = NSLocalizedString("Copy URL", comment: comment)
        
        class CopyURLAlert {
            private static let comment = "Library, Book Detail, Copy URL Alert"
            static let succeed = NSLocalizedString("URL Copied Successfully", comment: comment)
        }
        
        class SpaceAlert {
            private static let comment = "Library, Book Detail, Space Alert"
            static let downloadAnyway = NSLocalizedString("Download Anyway", comment: comment)
            static let spaceAlert = NSLocalizedString("Space Alert", comment: comment)
            static let message = NSLocalizedString("This book will take up more than 80% of your free space after downloaded", comment: comment)
        }
    }
}
