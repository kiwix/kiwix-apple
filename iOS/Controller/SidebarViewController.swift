//
//  SidebarViewController.swift
//  Kiwix
//
//  Created by Chris Li on 12/2/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit
import RealmSwift

class SidebarViewController: UIViewController {
    fileprivate let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        if #available(iOS 14.0, *), splitViewController != nil {
            navigationController?.isNavigationBarHidden = true
        }
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            view.backgroundColor = .white
        }
    }
    
    fileprivate func setContent(_ content: UIView) {
        guard !view.subviews.contains(content) else { return }
        view.subviews.forEach { $0.removeFromSuperview() }
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        if content === tableView {
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: content.topAnchor),
                view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
                view.leftAnchor.constraint(equalTo: content.leftAnchor),
                view.rightAnchor.constraint(equalTo: content.rightAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: content.topAnchor),
                view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
                view.safeAreaLayoutGuide.leftAnchor.constraint(equalTo: content.leftAnchor),
                view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: content.rightAnchor),
            ])
        }
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
}

class OutlineViewController: SidebarViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var webView: WKWebView?
    private var webViewURLObserver: NSKeyValueObservation?
    private var items = [OutlineItem]()
    private let emptyContentView = EmptyContentView(
        image: #imageLiteral(resourceName: "Compass"),
        title: NSLocalizedString(
            "Table of content not available", comment: "Help message when table of content is not available"
        )
    )
    
    init(webView: WKWebView) {
        super.init(nibName: nil, bundle: nil)
        self.webView = webView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Outline"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInsetReference = .fromAutomaticInsets
        setContent(tableView)
        
        webViewURLObserver = webView?.observe(\.url, options: [.initial, .new]) { [unowned self] webView, _ in
            self.reload(url: webView.url)
        }
    }
    
    func reload(url: URL?) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let zimFileID = url?.host, let path = url?.path,
               let parser = try? Parser(zimFileID: zimFileID, path: path) {
                self.items = parser.getOutlineItems()
            } else {
                self.items = []
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.items.isEmpty {
                    self.setContent(self.emptyContentView)
                } else {
                    self.setContent(self.tableView)
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource & UITableviewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let heading = items[indexPath.row]
        let indentationLevel = max(heading.level - 2, 0)
        
        cell.textLabel?.text = heading.text
        cell.textLabel?.numberOfLines = 0
        cell.separatorInset = UIEdgeInsets(top: 0, left: 20 * CGFloat(indentationLevel), bottom: 0, right: 0)
        if heading.level == 1 {
            cell.textLabel?.textAlignment = .center
        } else {
            cell.textLabel?.textAlignment = .left
        }
        if indentationLevel == 0 || heading.level == 1{
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = items[indexPath.row].index
        let javascript = "document.querySelectorAll(\"h1, h2, h3, h4, h5, h6\")[\(index)].scrollIntoView()"
        webView?.evaluateJavaScript(javascript, completionHandler: nil)
        tableView.deselectRow(at: indexPath, animated: true)
        if #available(iOS 14.0, *), let splitViewController = splitViewController, splitViewController.displayMode == .oneOverSecondary {
            splitViewController.hide(.primary)
        } else if let splitViewController = splitViewController, splitViewController.displayMode == .primaryOverlay {
            splitViewController.preferredDisplayMode = .primaryHidden
        } else {
            dismiss(animated: true)
        }
    }
}

class BookmarksViewController: SidebarViewController, UITableViewDataSource, UITableViewDelegate {
    private var bookmarks: Results<Bookmark>?
    private var observer: NotificationToken?
    private let emptyContentView = EmptyContentView(
        image: #imageLiteral(resourceName: "StarColor"),
        title: NSLocalizedString("Bookmark your favorite articles", comment: "Help message when there's no bookmark to show"),
        subtitle: NSLocalizedString("To add, long press the bookmark button on the tool bar when reading an article.", comment: "Help message when there's no bookmark to show")
    )
    var bookmarkTapped: ((URL) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let database = try? Realm(configuration: Realm.defaultConfig)
        self.bookmarks = database?.objects(Bookmark.self).sorted(byKeyPath: "date", ascending: false)
        navigationItem.title = "Bookmarks"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInsetReference = .fromAutomaticInsets
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        setContent(tableView)
        
        observer = bookmarks?.observe { [unowned self] change in
            switch change {
            case .initial(let results):
                self.tableView.reloadData()
                if results.isEmpty {
                    self.setContent(self.emptyContentView)
                } else {
                    self.setContent(self.tableView)
                }
            case .update(let results, let deletions, let insertions, let updates):
                if results.isEmpty {
                    self.tableView.reloadData()
                    self.setContent(self.emptyContentView)
                } else if results.count == 1 {
                    self.setContent(self.tableView)
                    self.tableView.reloadData()
                } else {
                    self.setContent(self.tableView)
                    self.tableView.performBatchUpdates({
                        self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }), with: .fade)
                        self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .fade)
                        updates.forEach({ row in
                            let indexPath = IndexPath(row: row, section: 0)
                            guard let cell = self.tableView.cellForRow(at: indexPath) as? ArticleTableViewCell else {return}
                            self.configure(cell: cell, indexPath: indexPath)
                        })
                    })
                }
            default:
                break
            }
        }
    }
    
    // MARK: - UITableViewDataSource & UITableviewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bookmarks?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ArticleTableViewCell
        configure(cell: cell, indexPath: indexPath)
        return cell
    }

    func configure(cell: ArticleTableViewCell, indexPath: IndexPath, animated: Bool = false) {
        guard let bookmark = bookmarks?[indexPath.row] else { return }
        cell.titleLabel.text = bookmark.title
        cell.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.detailLabel.text = bookmark.snippet
        
        if let zimFile = bookmark.zimFile, let thumbImagePath = bookmark.thumbImagePath,
           let data = ZimFileService.shared.getData(zimFileID: zimFile.fileID, contentPath: thumbImagePath) {
            cell.thumbImageView.image = UIImage(data: data)
        } else if let zimFile = bookmark.zimFile, let data = zimFile.faviconData {
            cell.thumbImageView.image = UIImage(data: data)
        } else {
            cell.thumbImageView.image = #imageLiteral(resourceName: "GenericZimFile")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let bookmark = bookmarks?[indexPath.row],
              let zimFileID = bookmark.zimFile?.fileID,
              let url = URL(zimFileID: zimFileID, contentPath: bookmark.path) else {
            present(UIAlertController.resourceUnavailable(), animated: true)
            return
        }
        bookmarkTapped?(url)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let bookmark = bookmarks?[indexPath.row], editingStyle == .delete else {return}
        BookmarkService().delete(bookmark)
    }
}
