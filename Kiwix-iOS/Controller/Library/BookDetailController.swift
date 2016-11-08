//
//  BookDetailController.swift
//  Kiwix
//
//  Created by Chris Li on 8/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class BookDetailController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var favIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasPicLabel: UILabel!
    
    fileprivate(set) var context: UnsafeMutableRawPointer? = nil
    
    var book: Book?
    fileprivate(set) var sectionHeaders = [String?]()
    fileprivate(set) var sectionFooters = [String?]()
    fileprivate(set) var cellTitles = [[String]]()
    var bookmarkCount: Int? {
        guard let book = book else {return nil}
        return Article.fetchBookmarked(in: book, with: AppDelegate.persistentContainer.viewContext).count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        hasPicIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        book?.addObserver(self, forKeyPath: "stateRaw", options: .new, context: context)
        configureViews()
        tableView.reloadEmptyDataSet()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        book?.removeObserver(self, forKeyPath: "stateRaw", context: context)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let book = object as? Book, context == self.context else {return}
        OperationQueue.main.addOperation {
            self.configureActionSection(with: book)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        }
    }
    
    // MARK: - Configure
    
    func configureStaticHeader(with book: Book) {
        title = book.title
        favIconImageView.image = UIImage(data: book.favIcon as Data? ?? Data())
        titleLabel.text = book.title
        titleLabel.isHidden = false
    }
    
    func configureIndicators(with book: Book) {
        hasPicIndicator.backgroundColor = book.hasPic ? AppColors.hasPicTintColor : UIColor.lightGray
        hasPicLabel.text = book.hasPic ? LocalizedStrings.hasPic : LocalizedStrings.noPic
        hasPicIndicator.isHidden = false
        hasPicLabel.isHidden = false
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
        
        switch book.state {
        case .cloud, .retained:
            if let _ = book.meta4URL {
                cellTitles[1] = book.spaceState == .notEnough ? [LocalizedStrings.spaceNotEnough] : [LocalizedStrings.download]
            } else {
                cellTitles[1] = [LocalizedStrings.addUsingiTunesFileSharing]
            }
        case .downloading:
            cellTitles[1] = [LocalizedStrings.downloading]
        case .local:
            cellTitles[1] = [LocalizedStrings.remove]
        }
    }
    
    func configureBookmarkSection(with book: Book) {
        guard bookmarkCount > 0 else {return}
        sectionHeaders.append(nil)
        sectionFooters.append(nil)
        cellTitles.append([LocalizedStrings.bookmarks])
    }
    
    func configureBookInfoSection(with book: Book) {
        sectionHeaders.append(LocalizedStrings.bookInfo)
        sectionFooters.append(nil)
        var titles = [
            LocalizedStrings.size,
            LocalizedStrings.createDate,
            LocalizedStrings.arcitleCount,
            LocalizedStrings.language,
            LocalizedStrings.creator,
            LocalizedStrings.publisher,
        ]
        if let _ = ZimMultiReader.shared.readers[book.id] {
            titles.append(LocalizedStrings.index)
        }
        cellTitles.append(titles)
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
        sectionHeaders.removeAll()
        sectionFooters.removeAll()
        cellTitles.removeAll()
        
        guard let book = book else {return}
        configureStaticHeader(with: book)
        configureIndicators(with: book)
        configureDescriptionSection(with: book)
        configureActionSection(with: book)
        configureBookmarkSection(with: book)
        configureBookInfoSection(with: book)
        configurePIDSection(with: book)
        configureURLSection(with: book)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return cellTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title = cellTitles[indexPath.section][indexPath.row]
        switch title {
        case LocalizedStrings.download, LocalizedStrings.downloading, LocalizedStrings.spaceNotEnough, LocalizedStrings.remove:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CenterTextCell", for: indexPath)
            cell.textLabel?.text = title
            
            switch title {
            case LocalizedStrings.download:
                if book?.spaceState == .caution {cell.textLabel?.textColor = UIColor.orange}
            case LocalizedStrings.downloading, LocalizedStrings.spaceNotEnough:
                cell.textLabel?.textColor = UIColor.gray
            case LocalizedStrings.remove:
                cell.textLabel?.textColor = UIColor.red
            default:
                break
            }
            return cell
        case LocalizedStrings.pid:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            cell.textLabel?.text = book?.pid
            return cell
        case LocalizedStrings.copyURL:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CenterTextCell", for: indexPath)
            cell.textLabel?.text = title
            return cell
        case LocalizedStrings.bookmarks:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailSegueCell", for: indexPath)
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = String(bookmarkCount ?? 0)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell", for: indexPath)
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
            case LocalizedStrings.index:
                guard let book = book, let reader = ZimMultiReader.shared.readers[book.id] else {break}
                cell.detailTextLabel?.text = {
                    if reader.hasIndex() {
                        if reader.idxFolderURL != nil {
                            return LocalizedStrings.external
                        } else {
                            return LocalizedStrings.embedded
                        }
                    } else {
                        return LocalizedStrings.none
                    }
                }()
            default:
                break
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionFooters[section]
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView, section == 0 else {return}
        view.textLabel?.textAlignment = .center
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        guard let cell = tableView.cellForRow(at: indexPath),
//            let title = cell.textLabel?.text,
//            let book = book else {return}
//        switch title {
//        case LocalizedStrings.download:
//            if book.spaceState == .caution {
//                let alert = SpaceCautionAlert(context: self, bookID: book.id)
//                GlobalQueue.shared.addOperation(alert)
//            } else {
//                guard let download = DownloadBookOperation(bookID: book.id) else {return}
//                Network.shared.queue.addOperation(download)
//            }
//        case LocalizedStrings.remove:
//            let operation = RemoveBookConfirmationAlert(context: self, bookID: book.id)
//            GlobalQueue.shared.addOperation(operation)
//        case LocalizedStrings.bookmarks:
//            guard let controller = UIStoryboard(name: "Bookmark", bundle: nil)
//                .instantiateViewController(withIdentifier: "BookmarkController") as? BookmarkController else {return}
//            controller.book = book
//            navigationController?.pushViewController(controller, animated: true)
//        case LocalizedStrings.copyURL:
//            guard let url = book.url else {return}
//            UIPasteboard.general.string = url.absoluteString
//            let operation = CopyURLAlert(url: url, context: self)
//            GlobalQueue.shared.addOperation(operation)
//        default:
//            return
//        }
    }
    
    class LocalizedStrings {
        static let hasPic = NSLocalizedString("Pictures", comment: "Library, Book Detail")
        static let noPic = NSLocalizedString("No Picture", comment: "Library, Book Detail")
        
        static let download = NSLocalizedString("Download", comment: "Library, Book Detail")
        static let downloading = NSLocalizedString("Downloading", comment: "Library, Book Detail")
        static let spaceNotEnough = NSLocalizedString("Space Not Enough", comment: "Library, Book Detail")
        static let remove = NSLocalizedString("Remove", comment: "Library, Book Detail")
        static let addUsingiTunesFileSharing = NSLocalizedString("Add using iTunes File Sharing", comment: "Library, Book Detail")
        
        static let bookmarks = NSLocalizedString("Bookmarks", comment: "Library, Book Detail")
        static let bookInfo = NSLocalizedString("Book Info", comment: "Library, Book Detail")
        static let size = NSLocalizedString("Size", comment: "Library, Book Detail")
        static let createDate = NSLocalizedString("Creation Date", comment: "Library, Book Detail")
        static let arcitleCount = NSLocalizedString("Article Count", comment: "Library, Book Detail")
        static let language = NSLocalizedString("Language", comment: "Library, Book Detail")
        static let creator = NSLocalizedString("Creator", comment: "Library, Book Detail")
        static let publisher = NSLocalizedString("Publisher", comment: "Library, Book Detail")
        static let index = NSLocalizedString("Index", comment: "Library, Book Detail")
        
        static let none = NSLocalizedString("None", comment: "Library, Book Detail, Index Status")
        static let embedded = NSLocalizedString("Embedded", comment: "Library, Book Detail, Index Status")
        static let external = NSLocalizedString("External", comment: "Library, Book Detail, Index Status")
        
        static let pid = NSLocalizedString("Persistent ID", comment: "Library, Book Detail")
        static let pidNote = NSLocalizedString("This ID does not change in different versions of the same book.", comment: "Library, Book Detail")
        
        static let copyURL = NSLocalizedString("Copy URL", comment: "Library, Book Detail")
    }
}
