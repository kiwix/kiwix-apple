//
//  TableOfContentViewController.swift
//  iOS
//
//  Created by Chris Li on 1/24/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class TableOfContentViewController: UITableViewController {
    weak var delegate: TableOfContentControllerDelegate? = nil
    
    var url: URL?
    var items = [TableOfContentItem]() {
        didSet {
            configureEmptyContentView()
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Table of Contents", comment: "Table of Content view title")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        configureEmptyContentView()
        tableView.reloadData()
    }
    
    private func configureEmptyContentView() {
        if items.count > 0 {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        } else {
            tableView.separatorStyle = .none
            let emptyContentView = EmptyContentView(image: #imageLiteral(resourceName: "Compass"), title: NSLocalizedString("Table of content not available", comment: "Help message when table of content is not available"))
            tableView.backgroundView = emptyContentView
        }
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
        delegate?.didTapTableOfContentItem(index: indexPath.row, item: items[indexPath.row])
        dismiss(animated: true) {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}

protocol TableOfContentControllerDelegate: class {
    func didTapTableOfContentItem(index: Int, item: TableOfContentItem)
}
