//
//  SearchResultsListController.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SearchResultsListController: UITableViewController {
    var results: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else {return}
        switch traitCollection.horizontalSizeClass {
        case .compact:
            tableView.backgroundColor = .groupTableViewBackground
        case .regular:
            tableView.backgroundColor = .clear
        case .unspecified:
            break
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        let result = results[indexPath.row]
        
        cell.backgroundColor = .clear
        cell.titleLabel.text = result.title
        cell.detailLabel.text = result.snippet
        cell.detailLabel.attributedText = result.attributedSnippet
        cell.thumbImageView.image = UIImage(data: Book.fetch(id: result.zimFileID, context: CoreDataContainer.shared.viewContext)?.favIcon ?? Data())
        cell.thumbImageView.contentMode = .scaleAspectFit
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let main = presentingViewController as? MainController else {return}
        
        if let parent = parent as? SearchResultController {
            parent.searchNoTextController.recentSearchTexts.insert(parent.searchText, at: 0)
        }
        
        main.load(url: results[indexPath.row].url)
        main.searchController.isActive = false
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if results[indexPath.row].snippet != nil || results[indexPath.row].attributedSnippet != nil {
            return traitCollection.horizontalSizeClass == .regular ? 120 : 190
        } else {
            return 44
        }
    }
}
