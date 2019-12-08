//
//  OutlineController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class OutlineController: UITableViewController {
    weak var delegate: OutlineControllerDelegate? = nil
    var url: URL?
    var items = [TableOfContentItem]() {
        didSet {
            if items.count > 0 {
                tableView.backgroundView = nil
                tableView.separatorStyle = .singleLine
            } else {
                tableView.separatorStyle = .none
                let emptyContentView = EmptyContentView(image: #imageLiteral(resourceName: "Compass"), title: NSLocalizedString("Table of content not available", comment: "Help message when table of content is not available"))
                tableView.backgroundView = emptyContentView
            }
            tableView.reloadData()
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Outline", comment: "Favorite view title")
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: "Outline",
                                      image: UIImage(systemName: "list.bullet"),
                                      selectedImage: UIImage(systemName: "list.bullet"))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if let _ = presentingViewController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissController))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
    }
    
    func updateContent() {
        tableView.separatorStyle = .none
        tableView.backgroundView = nil
        
        // update items
        if #available(iOS 13.0, *) {
            if let rootSplitController = (splitViewController ?? presentingViewController) as? RootSplitController,
                let currentWebViewController = rootSplitController.contentViewController.currentWebViewController {
                currentWebViewController.extractTableOfContents(completion: { (url, items) in
                    self.items = items
                })
            } else {
                self.items = []
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
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
        cell.textLabel?.text = heading.textContent
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
    func didTapOutlineItem(index: Int, item: TableOfContentItem)
}
