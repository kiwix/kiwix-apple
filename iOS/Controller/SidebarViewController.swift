//
//  SidebarViewController.swift
//  Kiwix
//
//  Created by Chris Li on 12/2/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class SidebarViewController: UIViewController {
    fileprivate let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        if splitViewController != nil {
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
    private var items = [OutlineItem]()
    
    convenience init(webView: WKWebView) {
        self.init(nibName: nil, bundle: nil)
        self.webView = webView
        navigationItem.title = "Outline"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInsetReference = .fromAutomaticInsets
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        items = []
        tableView.reloadData()
    }
    
    func reload() {
        webView?.evaluateJavaScript("outlines.getHeadingObjects()") { results, _ in
            self.items = (results as? [[String: Any]])?.compactMap({ OutlineItem(rawValue: $0) }) ?? [OutlineItem]()
            self.tableView.reloadData()
            if self.items.isEmpty {
                guard self.view.subviews.filter({ $0 is EmptyContentView }).first == nil else { return }
                let emptyContentView = EmptyContentView(
                    image: #imageLiteral(resourceName: "Compass"),
                    title: NSLocalizedString(
                        "Table of content not available", comment: "Help message when table of content is not available"
                    )
                )
                self.setContent(emptyContentView)
            } else {
                guard !self.view.subviews.contains(self.tableView) else { return }
                self.setContent(self.tableView)
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
        if indentationLevel == 0 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let javascript = "outlines.scrollToView(\(items[indexPath.row].index))"
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

class BookmarksViewController: SidebarViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Bookmarks"
    }
}
