//
//  LibraryBookDetailController.swift
//  iOS
//
//  Created by Chris Li on 10/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import CoreData

class LibraryBookDetailController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private(set) var book: Book?
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    private(set) var bookStateObserver: NSKeyValueObservation?
    private(set) var downloadTaskStateObserver: NSKeyValueObservation?
    
    var actions = (top: [[Action]](), bottom: [[Action]]()) {
        didSet(oldValue) {
            /*
             Docs: Batch Insertion, Deletion, and Reloading of Rows and Sections
             https://developer.apple.com/library/etc/redirect/xcode/content/1189/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html#//apple_ref/doc/uid/TP40007451-CH10-SW9
             */
            tableView.beginUpdates()
            if actions.top.count > oldValue.top.count {
                tableView.insertSections(IndexSet(integersIn: oldValue.top.count..<actions.top.count), with: .fade)
            } else if oldValue.top.count > actions.top.count {
                tableView.deleteSections(IndexSet(integersIn: actions.top.count..<oldValue.top.count), with: .fade)
            }
            if actions.bottom.count > oldValue.bottom.count {
                tableView.insertSections(IndexSet(integersIn: actions.top.count + metas.count + oldValue.bottom.count..<actions.top.count + metas.count + actions.bottom.count), with: .fade)
            } else if oldValue.bottom.count > actions.bottom.count {
                tableView.deleteSections(IndexSet(integersIn: oldValue.top.count + metas.count + actions.bottom.count..<oldValue.top.count + metas.count + oldValue.bottom.count), with: .fade)
            }
            tableView.reloadSections(IndexSet(integersIn: 0..<actions.top.count), with: .automatic)
//            tableView.reloadSections(IndexSet(integersIn: aboveSectionCount..<aboveSectionCount + actions.bottom.count), with: .automatic)
            tableView.endUpdates()
        }
    }
    
    private let metas: [[BookMeta]] = [
        [.language, .size, .date],
        [.hasPicture, .hasIndex],
        [.articleCount, .mediaCount],
        [.creator, .publisher],
        [.id]
    ]
    
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumIntegerDigits = 3
        formatter.minimumFractionDigits = 2
        formatter.maximumIntegerDigits = 2
        return formatter
    }()
    
    // MARK: - Enums
    
    enum BookMeta: String {
        case language, size, date, hasIndex, hasPicture, articleCount, mediaCount, creator, publisher, id
    }
    
    enum Action {
        case downloadWifiOnly, downloadWifiAndCellular, downloadSpaceNotEnough
        case cancel, resume, pause
        case deleteFile, deleteBookmarks, deleteFileAndBookmarks
        case openMainPage
        
        static let destructives: [Action] = [.cancel, .deleteFile, .deleteBookmarks, .deleteFileAndBookmarks]
        
        var isDestructive: Bool {
            return Action.destructives.contains(self)
        }
        
        var isDisabled: Bool {
            return self == .downloadSpaceNotEnough
        }
    }
    
    convenience init(book: Book) {
        self.init()
        self.book = book
        
        bookStateObserver = book.observe(\Book.stateRaw, options: [.initial, .new, .old]) { (_, change) in
            guard let newValue = change.newValue, let newState = BookState(rawValue: Int(newValue)) else {return}
            switch newState {
            case .cloud:
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let freespace: Int64 = {
                    if #available(iOS 11.0, *), let free = (try? url?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]))??.volumeAvailableCapacityForImportantUsage {
                        return free
                    } else if let path = url?.path, let free = ((try? FileManager.default.attributesOfFileSystem(forPath: path))?[.systemFreeSize] as? NSNumber)?.int64Value {
                        return free
                    } else {
                        return 0
                    }
                }()
                self.actions = (book.fileSize <= freespace ? [[.downloadWifiOnly, .downloadWifiAndCellular]] : [[.downloadSpaceNotEnough]], [])
            case .local:
                self.actions = ([[.openMainPage]], [[.deleteFile]])
            case .retained:
                self.actions = ([], [[.deleteBookmarks]])
            case .downloadQueued:
                self.actions = ([[.cancel]], [])
            case .downloading:
                self.actions = ([[.cancel, .pause]], [])
            case .downloadPaused:
                self.actions = ([[.cancel, .resume]], [])
            default:
                break
            }
        }
        title = book.title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LibraryActionCell.self, forCellReuseIdentifier: "ActionCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange),
//                                               name: .NSManagedObjectContextObjectsDidChange, object: book?.managedObjectContext)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
    }
    
//    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
//        guard let userInfo = notification.userInfo, let book = book,
//            let deletes = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.flatMap({ $0 as? Book }).filter({ $0.id == book.id }) else { return }
//        if deletes.count == 1 {
//            navigationController?.popViewController(animated: true)
//        }
//    }
    
    private func showDeletionConfirmationAlert(action: Action, bookID: String, localizedTitle: String?) {
        let message: String? = {
            switch action {
            case .deleteFile:
                return NSLocalizedString("This will delete the zim file but keep the bookmarks.", comment: "Book deletion message")
            case .deleteBookmarks:
                return NSLocalizedString("This will delete all bookmarks related to that zim file, but the zim file will remain on disk.", comment: "Book deletion message")
            case .deleteFileAndBookmarks:
                return NSLocalizedString("This will delete both the zim file and all its bookmarks.", comment: "Book deletion message")
            default:
                return nil
            }
        }()
        let controller = UIAlertController(title: localizedTitle, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Book deletion confirmation"), style: .destructive, handler: { _ in
            if action == .deleteFile || action == .deleteFileAndBookmarks {
                guard let url = ZimMultiReader.shared.getFileURL(zimFileID: bookID) else {return}
                let directoryURL = url.deletingLastPathComponent()
                let fileName = url.deletingPathExtension().lastPathComponent
                
                let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isExcludedFromBackupKey],
                                                                        options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
                urls?.filter({ $0.lastPathComponent.contains(fileName) }).forEach({ try? FileManager.default.removeItem(at: $0) })
            }
            if action == .deleteBookmarks || action == .deleteFileAndBookmarks {
            }
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Book deletion confirmation"), style: .cancel, handler: nil))
        present(controller, animated: true)
    }
    
    // MARK: - UITableViewDataSource & Delagates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.top.count + metas.count + actions.bottom.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < actions.top.count {
            return actions.top[section].count
        } else if section < actions.top.count + metas.count {
            return metas[section - actions.top.count].count
        } else {
            return actions.bottom[section - metas.count - actions.top.count].count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func configureCell(cell: LibraryActionCell, action: Action) {
            switch action {
            case .downloadWifiOnly:
                cell.textLabel?.text = NSLocalizedString("Download - Wifi Only", comment: "Book Detail Cell")
            case .downloadWifiAndCellular:
                cell.textLabel?.text = NSLocalizedString("Download - Wifi & Cellular", comment: "Book Detail Cell")
            case .downloadSpaceNotEnough:
                cell.textLabel?.text = NSLocalizedString("Download - Space Not Enough", comment: "Book Detail Cell")
            case .cancel:
                cell.textLabel?.text = NSLocalizedString("Cancel", comment: "Book Detail Cell")
            case .resume:
                cell.textLabel?.text = NSLocalizedString("Resume", comment: "Book Detail Cell")
            case .pause:
                cell.textLabel?.text = NSLocalizedString("Pause", comment: "Book Detail Cell")
            case .deleteFile:
                cell.textLabel?.text = NSLocalizedString("Delete File", comment: "Book Detail Cell")
            case .deleteBookmarks:
                cell.textLabel?.text = NSLocalizedString("Delete Bookmarks", comment: "Book Detail Cell")
            case .deleteFileAndBookmarks:
                cell.textLabel?.text = NSLocalizedString("Delete File and Bookmarks", comment: "Book Detail Cell")
            case .openMainPage:
                cell.textLabel?.text = NSLocalizedString("Open Main Page", comment: "Book Detail Cell")
            }
            if action.isDestructive {cell.isDestructive = true}
            if action.isDisabled {cell.isDisabled = true}
        }
        
        if indexPath.section < actions.top.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! LibraryActionCell
            cell.indentationLevel = 0
            let action = actions.top[indexPath.section][indexPath.row]
            configureCell(cell: cell, action: action)
            return cell
        } else if indexPath.section >= actions.top.count + metas.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! LibraryActionCell
            cell.indentationLevel = 0
            let action = actions.bottom[indexPath.section - actions.top.count - metas.count][indexPath.row]
            configureCell(cell: cell, action: action)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MetaCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "MetaCell")
            guard let book = book else {return cell}
            let meta = metas[indexPath.section - actions.top.count][indexPath.row]
            cell.selectionStyle = .none
            switch meta {
            case .language:
                cell.textLabel?.text = NSLocalizedString("Language", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book.language?.nameInOriginalLocale
            case .size:
                cell.textLabel?.text = NSLocalizedString("Size", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book.fileSizeDescription
            case .date:
                cell.textLabel?.text = NSLocalizedString("Date", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book.dateDescription
            case .hasIndex:
                cell.textLabel?.text = NSLocalizedString("Indexed", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = {
                    if book.state == .local {
                        if ZimMultiReader.shared.hasEmbeddedIndex(id: book.id) {
                            return NSLocalizedString("Embedded", comment: "Book Detail Cell, has index")
                        } else if ZimMultiReader.shared.hasExternalIndex(id: book.id) {
                            return NSLocalizedString("External", comment: "Book Detail Cell, has index")
                        } else {
                            return NSLocalizedString("No", comment: "Book Detail Cell, has index")
                        }
                    } else {
                        if book.hasIndex {
                            return NSLocalizedString("Embedded", comment: "Book Detail Cell, does not have index")
                        } else {
                            return NSLocalizedString("No", comment: "Book Detail Cell, does not have index")
                        }
                    }
                }()
            case .hasPicture:
                cell.textLabel?.text = NSLocalizedString("Pictures", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book.hasPic ? NSLocalizedString("Yes", comment: "Book Detail Cell, has picture") : NSLocalizedString("No", comment: "Book Detail Cell, does not have picture")
            case .articleCount:
                cell.textLabel?.text = NSLocalizedString("Article Count", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = "\(book.articleCount)"
            case .mediaCount:
                cell.textLabel?.text = NSLocalizedString("Media Count", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = "\(book.mediaCount)"
            case .creator:
                cell.textLabel?.text = NSLocalizedString("Creator", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book.creator
            case .publisher:
                cell.textLabel?.text = NSLocalizedString("Publisher", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book.publisher
            case .id:
                cell.textLabel?.text = NSLocalizedString("ID", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = String(book.id.prefix(8))
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func handle(action: Action, book: Book, cell: LibraryActionCell) {
            switch action {
            case .downloadWifiOnly:
                Network.shared.start(bookID: book.id, allowsCellularAccess: false)
            case .downloadWifiAndCellular:
                Network.shared.start(bookID: book.id, allowsCellularAccess: true)
            case .downloadSpaceNotEnough:
                break
            case .cancel:
                Network.shared.cancel(bookID: book.id)
            case .pause:
                Network.shared.pause(bookID: book.id)
            case .resume:
                Network.shared.resume(bookID: book.id)
            case .deleteFile:
                showDeletionConfirmationAlert(action: action, bookID: book.id, localizedTitle: cell.textLabel?.text)
            case .deleteBookmarks:
                showDeletionConfirmationAlert(action: action, bookID: book.id, localizedTitle: cell.textLabel?.text)
            case .deleteFileAndBookmarks:
                showDeletionConfirmationAlert(action: action, bookID: book.id, localizedTitle: cell.textLabel?.text)
            case .openMainPage:
                guard let main = (presentingViewController as? UINavigationController)?.topViewController as? MainController,
                    let url = ZimMultiReader.shared.getMainPageURL(bookID: book.id) else {break}
                main.load(url: url)
                dismiss(animated: true, completion: nil)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        guard let book = book, let cell = tableView.cellForRow(at: indexPath) as? LibraryActionCell else {return}
        if indexPath.section < actions.top.count {
            let action = actions.top[indexPath.section][indexPath.row]
            handle(action: action, book: book, cell: cell)
        } else if indexPath.section >= actions.top.count + metas.count {
            let action = actions.bottom[indexPath.section - actions.top.count - metas.count][indexPath.row]
            handle(action: action, book: book, cell: cell)
        }
    }
}
