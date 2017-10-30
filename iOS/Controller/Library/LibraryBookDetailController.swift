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
    var actions = [[String]]()
    let meta = [
        [Titles.size, Titles.date],
        [Titles.articleCount, Titles.mediaCount, Titles.globalCount]
    ]
    
    struct Titles {
        static let downloadWifiOnly = NSLocalizedString("Download - Wifi Only", comment: "Book Detail Cell")
        static let downloadWifiAndCellular = NSLocalizedString("Download - Wifi & Cellular", comment: "Book Detail Cell")
        static let cancel = NSLocalizedString("Cancel", comment: "Book Detail Cell")
        static let resume = NSLocalizedString("Resume", comment: "Book Detail Cell")
        static let pause = NSLocalizedString("Pause", comment: "Book Detail Cell")
        static let deleteFile = NSLocalizedString("Delete File", comment: "Book Detail Cell")
        static let deleteBookmarks = NSLocalizedString("Delete Bookmarks", comment: "Book Detail Cell")
        static let deleteFileAndBookmarks = NSLocalizedString("Delete File and Bookmarks", comment: "Book Detail Cell")
        static let openMainPage = NSLocalizedString("Open Main Page", comment: "Book Detail Cell")
        static let size = NSLocalizedString("Size", comment: "Book Detail Cell")
        static let date = NSLocalizedString("Date", comment: "Book Detail Cell")
        static let articleCount = NSLocalizedString("Article Count", comment: "Book Detail Cell")
        static let mediaCount = NSLocalizedString("Media Count", comment: "Book Detail Cell")
        static let globalCount = NSLocalizedString("Global Count", comment: "Book Detail Cell")
    }
    
    convenience init(book: Book) {
        self.init()
        self.book = book
        self.observer = book.observe(\Book.stateRaw, options: [.initial, .new]) { (book, change) in
            guard change.newValue != change.oldValue, let newValue = change.newValue, let state = BookState(rawValue: Int(newValue)) else {return}
            switch state {
            case .cloud:
                self.actions = [[Titles.downloadWifiOnly, Titles.downloadWifiAndCellular]]
            case .downloading:
                self.actions = [[Titles.cancel, Titles.pause]]
            case .local:
                self.actions = [[Titles.deleteFile, Titles.deleteBookmarks, Titles.deleteFileAndBookmarks],
                           [Titles.openMainPage]]
            case .retained:
                self.actions = [[Titles.deleteBookmarks]]
            }
            self.tableView.reloadData()
        }
        title = book.title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
    }
    
    // MARK: - UITableViewDataSource & Delagates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count + meta.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section < actions.count ? actions[section].count : meta[section-actions.count].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < actions.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
            let title = actions[indexPath.section][indexPath.row]
            cell.textLabel?.text = title
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            cell.textLabel?.textColor = [Titles.openMainPage, Titles.pause, Titles.resume].contains(title) ? #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1) : #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "Cell")
            let title = meta[indexPath.section-actions.count][indexPath.row]
            cell.textLabel?.text = title
            cell.selectionStyle = .none
            switch title {
            case Titles.size:
                cell.detailTextLabel?.text = book?.fileSizeDescription
            case Titles.date:
                cell.detailTextLabel?.text = book?.dateDescription
            case Titles.articleCount:
                if let count = book?.articleCount {cell.detailTextLabel?.text = "\(count)"}
            case Titles.mediaCount:
                if let count = book?.mediaCount {cell.detailTextLabel?.text = "\(count)"}
            case Titles.globalCount:
                if let count = book?.globalCount {cell.detailTextLabel?.text = "\(count)"}
            default:
                break
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let book = book else {return}
        if indexPath.section < actions.count {
            let title = actions[indexPath.section][indexPath.row]
            switch title {
            case Titles.cancel:
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


