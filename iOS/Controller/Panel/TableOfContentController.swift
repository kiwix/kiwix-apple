//
//  TableOfContentController.swift
//  Kiwix
//
//  Created by Chris Li on 11/13/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class TableOfContentController: PanelTabController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    let emptyBackgroundView = BackgroundStackView(image: #imageLiteral(resourceName: "Compass"), text: NSLocalizedString("Table of content not available", comment: "Empty Library"))
    weak var delegate: TableOfContentControllerDelegate? = nil
    
    var url: URL?
    var items = [TableOfContentItem]() {
        didSet {
            if items.count == 0 {
                configure(stackView: emptyBackgroundView)
            } else {
                configure(tableView: tableView)
            }
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        configure(stackView: emptyBackgroundView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didTapTableOfContentItem(index: indexPath.row, item: items[indexPath.row])
    }
}

protocol TableOfContentControllerDelegate: class {
    func didTapTableOfContentItem(index: Int, item: TableOfContentItem)
}
