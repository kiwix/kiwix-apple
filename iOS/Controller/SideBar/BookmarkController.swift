//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 5/21/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift

class BookmarkController: UITableViewController {
    weak var delegate: BookmarkControllerDelegate? = nil
    private lazy var emptyContentView = EmptyContentView(
        image: #imageLiteral(resourceName: "StarColor"),
        title: NSLocalizedString("Bookmark your favorite articles", comment: "Help message when there's no bookmark to show"),
        subtitle: NSLocalizedString("To add, long press the bookmark button on the tool bar when reading an article.", comment: "Help message when there's no bookmark to show"))
    private var bookmarks: Results<Bookmark>?
    private var changeToken: NotificationToken?
    
    // MARK: - Override
    
    init(zimFiles: [ZimFile]? = nil) {
        let database = try? Realm(configuration: Realm.defaultConfig)
        if let zimFiles = zimFiles, zimFiles.count > 0 {
            self.bookmarks = database?.objects(Bookmark.self).filter("zimFile IN %@", Set(zimFiles)).sorted(byKeyPath: "date", ascending: false)
        } else {
            self.bookmarks = database?.objects(Bookmark.self).sorted(byKeyPath: "date", ascending: false)
        }
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Bookmark", comment: "Bookmark view title")
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: "Bookmark",
                                      image: UIImage(systemName: "star"),
                                      selectedImage: UIImage(systemName: "star.fill"))
        } else {
            tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInsetReference = .fromAutomaticInsets
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        if let _ = presentingViewController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissController))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureBackground()
        configureChangeToken()
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        changeToken = nil
    }
    
    // MARK: -
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureBackground() {
        if bookmarks?.count ?? 0 > 0 {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        } else {
            tableView.backgroundView = emptyContentView
            tableView.separatorStyle = .none
        }
    }
    
    private func configureChangeToken() {
        changeToken = bookmarks?.observe({ (changes) in
            guard case .update(_, let deletions, let insertions, let updates) = changes else {return}
            self.configureBackground()
            self.tableView.performBatchUpdates({
                self.configureBackground()
                self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }), with: .fade)
                self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .fade)
                updates.forEach({ row in
                    let indexPath = IndexPath(row: row, section: 0)
                    guard let cell = self.tableView.cellForRow(at: indexPath) as? TableViewCell else {return}
                    self.configure(cell: cell, indexPath: indexPath)
                })
            }, completion: nil)
        })
    }
    
    // MARK: - UITableViewDataSource & Delagate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }

    func configure(cell: TableViewCell, indexPath: IndexPath, animated: Bool = false) {
        guard let bookmark = bookmarks?[indexPath.row] else {return}
        cell.titleLabel.text = bookmark.title
        cell.detailLabel.text = bookmark.snippet
        cell.thumbImageView.image = UIImage(data: bookmark.thumbImageData ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile")
        cell.thumbImageView.contentMode = .scaleAspectFill
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookmark = bookmarks?[indexPath.row], let zimFileID = bookmark.zimFile?.id,
            let url = URL(zimFileID: zimFileID, contentPath: bookmark.path) else {return}
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didTapBookmark(url: url)
        dismiss(animated: true) {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard let bookmark = bookmarks?[indexPath.row], editingStyle == .delete else {return}
        if let zimFileID = bookmark.zimFile?.id, let url = URL(zimFileID: zimFileID, contentPath: bookmark.path) {
            delegate?.didDeleteBookmark(url: url)
        }
        BookmarkService().delete(bookmark)
    }
}

// MARK: - Protocols

protocol BookmarkControllerDelegate: class {
    func didTapBookmark(url: URL)
    func didDeleteBookmark(url: URL)
}
