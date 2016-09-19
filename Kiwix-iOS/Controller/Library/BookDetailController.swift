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
            self.configureActionSection(with: book)
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Configure
    
    func configureStaticHeader(with book: Book) {
        title = book.title
        favIconImageView.image = UIImage(data: book.favIcon ?? NSData())
        titleLabel.text = book.title
        titleLabel.hidden = false
    }
    
    func configureIndicators(with book: Book) {
        hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGrayColor()
        hasPicLabel.text = book.hasPic ? LocalizedStrings.hasPic : LocalizedStrings.noPic
        hasIndexIndicator.backgroundColor = book.hasIndex ? AppColors.hasIndexTintColor : UIColor.lightGrayColor()
        hasIndexLabel.text = book.hasIndex ? LocalizedStrings.hasIndex : LocalizedStrings.noIndex
        
        hasPicIndicator.hidden = false
        hasPicLabel.hidden = false
        hasIndexIndicator.hidden = false
        hasIndexLabel.hidden = false
    }
    
    func configureDescriptionSection(with book: Book) {
        sectionHeaders.append(nil)
        sectionFooters.append(book.desc)
        cellTitles.append([String]())
    }
    
    func configureActionSection(with book: Book) {
        if cellTitles.count == 1 {
            sectionHeaders.append(nil)
            sectionFooters.append(nil)
            cellTitles.append([])
        }
        
        if let isLocal = book.isLocal?.boolValue {
            if isLocal {
                cellTitles[1] = [LocalizedStrings.remove]
            } else {
                cellTitles[1] = book.spaceState == .NotEnough ? [LocalizedStrings.spaceNotEnough] : [LocalizedStrings.download]
            }
        } else {
            cellTitles[1] = [LocalizedStrings.downloading]
        }
    }
    
    func configureBookInfoSection(with book: Book) {
        sectionHeaders.append(LocalizedStrings.bookInfo)
        sectionFooters.append(nil)
        cellTitles.append([
            LocalizedStrings.size,
            LocalizedStrings.createDate,
            LocalizedStrings.arcitleCount,
            LocalizedStrings.language,
            LocalizedStrings.creator,
            LocalizedStrings.publisher
        ])
    }
    
    func configurePIDSection(with book: Book) {
        guard let _ = book.pid else {return}
        sectionHeaders.append(LocalizedStrings.pid)
        sectionFooters.append(LocalizedStrings.pidNote)
        cellTitles.append([LocalizedStrings.pid])
    }
    
    func configureURLSection(with book: Book) {
        guard let _ = book.url else {return}
        sectionHeaders.append(nil)
        sectionFooters.append(nil)
        cellTitles.append([LocalizedStrings.copyURL])
    }
    
    func configureViews() {
        guard let book = book else {return}
        configureStaticHeader(with: book)
        configureIndicators(with: book)
        configureDescriptionSection(with: book)
        configureActionSection(with: book)
        configureBookInfoSection(with: book)
        configurePIDSection(with: book)
        configureURLSection(with: book)
        tableView.reloadEmptyDataSet()
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
        case LocalizedStrings.download, LocalizedStrings.downloading, LocalizedStrings.spaceNotEnough, LocalizedStrings.remove:
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = title
            
            switch title {
            case LocalizedStrings.download:
                if book?.spaceState == .Caution {cell.textLabel?.textColor = UIColor.orangeColor()}
            case LocalizedStrings.downloading, LocalizedStrings.spaceNotEnough:
                cell.textLabel?.textColor = UIColor.grayColor()
            case LocalizedStrings.remove:
                cell.textLabel?.textColor = UIColor.redColor()
            default:
                break
            }
            return cell
        case LocalizedStrings.pid:
            let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
            cell.textLabel?.text = book?.pid
            return cell
        case LocalizedStrings.copyURL:
            let cell = tableView.dequeueReusableCellWithIdentifier("CenterTextCell", forIndexPath: indexPath)
            cell.textLabel?.text = title
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("RightDetailCell", forIndexPath: indexPath)
            cell.textLabel?.text = title
            switch title {
            case LocalizedStrings.size:
                cell.detailTextLabel?.text = book?.fileSizeDescription
            case LocalizedStrings.createDate:
                cell.detailTextLabel?.text = book?.dateDescription
            case LocalizedStrings.arcitleCount:
                cell.detailTextLabel?.text = book?.articleCountString
            case LocalizedStrings.language:
                cell.detailTextLabel?.text = book?.language?.nameInCurrentLocale
            case LocalizedStrings.creator:
                cell.detailTextLabel?.text = book?.creator
            case LocalizedStrings.publisher:
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
        case LocalizedStrings.download:
            if book.spaceState == .Caution {
                let alert = SpaceCautionAlert(context: self, bookID: book.id)
                GlobalQueue.shared.addOperation(alert)
            } else {
                guard let download = DownloadBookOperation(bookID: book.id) else {return}
                Network.shared.queue.addOperation(download)
            }
        case LocalizedStrings.remove:
            let operation = RemoveBookConfirmationAlert(context: self, bookID: book.id)
            GlobalQueue.shared.addOperation(operation)
        case LocalizedStrings.copyURL:
            guard let url = book.url else {return}
            UIPasteboard.generalPasteboard().string = url.absoluteString
            let operation = CopyURLAlert(url: url, context: self)
            GlobalQueue.shared.addOperation(operation)
        default:
            return
        }
    }
    
    class LocalizedStrings {
        private static let comment = "Library, Book Detail"
        static let hasIndex = NSLocalizedString("Index", comment: comment)
        static let hasPic = NSLocalizedString("Pictures", comment: comment)
        static let noIndex = NSLocalizedString("No Index", comment: comment)
        static let noPic = NSLocalizedString("No Picture", comment: comment)
        
        static let download = NSLocalizedString("Download", comment: comment)
        static let downloading = NSLocalizedString("Downloading", comment: comment)
        static let spaceNotEnough = NSLocalizedString("Space Not Enough", comment: comment)
        static let remove = NSLocalizedString("Remove", comment: comment)
//        static let pause = NSLocalizedString("Pause", comment: comment)
//        static let resume = NSLocalizedString("Resume", comment: comment)
//        static let cancel = NSLocalizedString("Cancel", comment: comment)
        
        static let bookInfo = NSLocalizedString("Book Info", comment: comment)
        static let size = NSLocalizedString("Size", comment: comment)
        static let createDate = NSLocalizedString("Creation Date", comment: comment)
        static let arcitleCount = NSLocalizedString("Article Count", comment: comment)
        static let language = NSLocalizedString("Language", comment: comment)
        static let creator = NSLocalizedString("Creator", comment: comment)
        static let publisher = NSLocalizedString("Publisher", comment: comment)
        
        static let pid = NSLocalizedString("Persistent ID", comment: comment)
        static let pidNote = NSLocalizedString("This ID does not change in different versions of the same book.", comment: comment)
        
        static let copyURL = NSLocalizedString("Copy URL", comment: comment)
    }
}
