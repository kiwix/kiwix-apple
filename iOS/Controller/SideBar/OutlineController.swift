//
//  OutlineController.swift
//  Kiwix
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class OutlineController: UITableViewController {
    static let title = NSLocalizedString("Outline", comment: "Outline view title")
    
    weak var delegate: OutlineControllerDelegate? = nil
    private var url: URL?
    private var items = [OutlineItem]()
    private var levelOneItems = [OutlineItem]()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = OutlineController.title
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

        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if let _ = presentingViewController {
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
        let rootController = (splitViewController ?? presentingViewController) as? RootController
        guard let webViewController = rootController?.contentController.webViewController else {
            navigationItem.title = OutlineController.title
            updateContent(url: nil, items: [])
            return
        }
        
        if webViewController.currentURL == url { return }
        
        navigationItem.title = webViewController.currentTitle
        webViewController.extractTableOfContents(completion: { (url, items) in
            self.updateContent(url: url, items: items)
        })
    }
    
    private func updateContent(url: URL?, items: [OutlineItem]) {
        self.url = url
        self.items = items
        self.levelOneItems = items.filter({ $0.level == 1 })
        
        if items.count > 0 {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
        } else {
            tableView.separatorStyle = .none
            tableView.backgroundView = EmptyContentView(
                image: #imageLiteral(resourceName: "Compass"),
                title: NSLocalizedString(
                    "Table of content not available", comment: "Help message when table of content is not available"
                )
            )
        }
        tableView.reloadData()
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
        cell.backgroundColor = .clear
        cell.indentationLevel = (heading.level - 1) * 2
        cell.textLabel?.text = heading.text
        cell.textLabel?.numberOfLines = 0
        if cell.indentationLevel == 0 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapOutlineItem(index: indexPath.row, item: items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true)
    }
}

protocol OutlineControllerDelegate: class {
    func didTapOutlineItem(index: Int, item: OutlineItem)
}

struct OutlineItem {
    let text: String
    let level: Int
    
    init?(rawValue: [String: Any]) {
        if let text = (rawValue["textContent"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
            let tagName = rawValue["tagName"] as? String,
            let level = Int(tagName.replacingOccurrences(of: "H", with: ""))
        {
            self.text = text
            self.level = level
        } else {
            return nil
        }
    }
}
