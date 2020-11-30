//
//  OutlineController.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import WebKit

class OutlineViewController: UITableViewController {
    private weak var webView: WKWebView?
    private var items = [OutlineItem]()
    
    convenience init(webView: WKWebView) {
        self.init(style: UITableView.Style.plain)
        self.webView = webView
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
        navigationItem.title = "Outline"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInsetReference = .fromAutomaticInsets
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if splitViewController != nil {
            navigationController?.isNavigationBarHidden = true
        }
        reload()
    }
    
    func reload() {
        webView?.evaluateJavaScript("outlines.getHeadingObjects()") { results, _ in
            self.items = (results as? [[String: Any]])?.compactMap({ OutlineItem(rawValue: $0) }) ?? [OutlineItem]()
            self.tableView.reloadData()
        }
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableviewDelegate & UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let javascript = "outlines.scrollToView(\(items[indexPath.row].index))"
        webView?.evaluateJavaScript(javascript, completionHandler: nil)
        if #available(iOS 14.0, *), let splitViewController = splitViewController, splitViewController.displayMode == .oneOverSecondary {
            splitViewController.hide(.primary)
        } else if let splitViewController = splitViewController, splitViewController.displayMode == .primaryOverlay {
            splitViewController.preferredDisplayMode = .primaryHidden
        } else {
            dismiss(animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

class OutlineController: UITableViewController {
    static let title = NSLocalizedString("Outline", comment: "Outline view title")
    weak var delegate: OutlineControllerDelegate? = nil
    private let emptyContentView = EmptyContentView(
        image: #imageLiteral(resourceName: "Compass"),
        title: NSLocalizedString(
            "Table of content not available", comment: "Help message when table of content is not available"
        )
    )
    private var url: URL?
    private var items = [OutlineItem]()
    private var highestLevel = 1
    
    // MARK: - 
    
    init() {
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: "Outline",
                                      image: UIImage(systemName: "list.bullet"),
                                      selectedImage: UIImage(systemName: "list.bullet"))
        } else {
            tabBarItem = UITabBarItem(title: "Outline",
                                      image: UIImage(named: "list.bullet"),
                                      selectedImage: UIImage(named: "list.bullet"))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.separatorInsetReference = .fromAutomaticInsets
        
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissController))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Configurations

    func update() {
        guard let rootController = (splitViewController ?? presentingViewController) as? RootController else { return }
        let webViewController = rootController.webViewController
        
        // Show empty content view if no article is displayed
        guard webViewController.currentURL != nil else {
            navigationItem.title = OutlineController.title
            tableView.backgroundView = emptyContentView
            tableView.separatorStyle = .none
            return
        }
        
        // No need to update if already showing outline of current article
        guard webViewController.currentURL != url else { return }
        
        /*
         Before the update, clear previous article outline. This way we can prevent
         the previous article outline from briefly appear which is not desirable.
         */
        items = []
        tableView.reloadData()
        
        navigationItem.title = webViewController.currentTitle ?? OutlineController.title
        webViewController.extractOutlineItems(completion: { (url, items) in
            self.url = url
            self.items = items
            
            /*
             Hack: Often the whole article has only one h1 and that happens to be the title.
             In this case, removing this h1 to prevent the whole list being unnecessarily indented.
             */
            if self.items.filter({ $0.level == 1 }).count == 1,
               let firstItem = self.items.first,
               firstItem.level == 1,
               firstItem.text == self.navigationItem.title {
                self.items.removeFirst()
            }
            self.highestLevel = self.items.map({ $0.level }).min() ?? 1
            
            if items.count > 0 {
                self.tableView.backgroundView = nil
                self.tableView.separatorStyle = .singleLine
            } else {
                self.tableView.backgroundView = self.emptyContentView
                self.tableView.separatorStyle = .none
            }
            self.tableView.reloadData()
        })
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let heading = items[indexPath.row]
        let indentationLevel = heading.level - highestLevel
        
        cell.textLabel?.text = heading.text
        cell.textLabel?.numberOfLines = 0
        cell.separatorInset = UIEdgeInsets(top: 0, left: 20 * CGFloat(indentationLevel), bottom: 0, right: 0)
        if indentationLevel == 0 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapOutlineItem(item: items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true)
    }
}

protocol OutlineControllerDelegate: class {
    func didTapOutlineItem(item: OutlineItem)
}

struct OutlineItem {
    let index: Int
    let text: String
    let level: Int
    
    init?(rawValue: [String: Any]) {
        if let index = rawValue["index"] as? Int,
            let tagName = rawValue["tagName"] as? String,
            let level = Int(tagName.replacingOccurrences(of: "H", with: "")),
            let text = (rawValue["textContent"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        {
            self.index = index
            self.level = level
            self.text = text
        } else {
            return nil
        }
    }
}
