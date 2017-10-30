//
//  LibraryBookDetailController.swift
//  iOS
//
//  Created by Chris Li on 10/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryBookDetailController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private(set) var book: Book?
    private(set) var observer: NSKeyValueObservation?
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    var actions = [[Action]]()
    let metas: [[BookMeta]] = [
        [.size, .date],
        [.articleCount, .mediaCount, .globalCount]
    ]
    
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
    
    enum BookMeta: String {
        case size, date, articleCount, mediaCount, globalCount
    }
    
    convenience init(book: Book) {
        self.init()
        self.book = book
        self.observer = book.observe(\Book.stateRaw, options: [.initial, .new]) { (book, change) in
            guard change.newValue != change.oldValue, let newValue = change.newValue, let state = BookState(rawValue: Int(newValue)) else {return}
            switch state {
            case .cloud:
                self.actions = [[.downloadWifiOnly, .downloadWifiAndCellular]]
            case .downloading:
                self.actions = [[.cancel, .pause]]
            case .local:
                self.actions = [[.deleteFile, .deleteBookmarks, .deleteFileAndBookmarks], [.openMainPage]]
            case .retained:
                self.actions = [[.deleteBookmarks]]
            }
            self.tableView.reloadData()
        }
        title = book.title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LibraryActionCell.self, forCellReuseIdentifier: "ActionCell")
    }
    
    // MARK: - UITableViewDataSource & Delagates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count + metas.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section < actions.count ? actions[section].count : metas[section-actions.count].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < actions.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! LibraryActionCell
            let action = actions[indexPath.section][indexPath.row]
            if action.isDestructive {cell.isDestructive = true}
            if action.isDestructive {cell.isDestructive = true}
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
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "Cell")
            let meta = metas[indexPath.section-actions.count][indexPath.row]
            cell.selectionStyle = .none
            switch meta {
            case .size:
                cell.textLabel?.text = NSLocalizedString("Size", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book?.fileSizeDescription
            case .date:
                cell.textLabel?.text = NSLocalizedString("Date", comment: "Book Detail Cell")
                cell.detailTextLabel?.text = book?.dateDescription
            case .articleCount:
                cell.textLabel?.text = NSLocalizedString("Article Count", comment: "Book Detail Cell")
                if let count = book?.articleCount {cell.detailTextLabel?.text = "\(count)"}
            case .mediaCount:
                cell.textLabel?.text = NSLocalizedString("Media Count", comment: "Book Detail Cell")
                if let count = book?.mediaCount {cell.detailTextLabel?.text = "\(count)"}
            case .globalCount:
                cell.textLabel?.text = NSLocalizedString("Global Count", comment: "Book Detail Cell")
                if let count = book?.globalCount {cell.detailTextLabel?.text = "\(count)"}
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let book = book else {return}
        if indexPath.section < actions.count {
            let action = actions[indexPath.section][indexPath.row]
            switch action {
            case .cancel:
                Network.shared.cancel(bookID: book.id)
            default:
                break
            }
        }
//        if indexPath.section == 0 {
//            let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: "Book Delete Confirmation"), message: "", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive, handler: { _ in
//                print("book delete")
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//            present(alert, animated: true, completion: nil)
//        }
    }
}


