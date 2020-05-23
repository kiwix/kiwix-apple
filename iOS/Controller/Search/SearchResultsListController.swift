//
//  SearchResultsListController.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftyUserDefaults

class SearchResultsListController: UITableViewController {
    private(set) var searchText: String = ""
    private(set) var zimFileIDs = Set<String>()
    private(set) var results = [SearchResult]()
    private weak var clearResultTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorInsetReference = .fromAutomaticInsets
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }
    
    func update(searchText: String, zimFileIDs: Set<String>, results: [SearchResult]) {
        self.searchText = searchText
        self.zimFileIDs = zimFileIDs
        self.results = results
        tableView.reloadData()
        if !results.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    func update(recentSearchText newSearchText: String) {
        var searchTexts = Defaults.recentSearchTexts
        if let index = searchTexts.firstIndex(of: newSearchText) {
            searchTexts.remove(at: index)
        }
        searchTexts.insert(newSearchText, at: 0)
        if searchTexts.count > 20 {
            searchTexts = Array(searchTexts[..<20])
        }
        Defaults.recentSearchTexts = searchTexts
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearResultTimer?.invalidate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearResultTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { (_) in
            self.update(searchText: "", zimFileIDs: Set(), results: [])
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchResultTableViewCell
        let result = results[indexPath.row]
        cell.titleLabel.text = result.title
        
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let zimFile = database.object(ofType: ZimFile.self, forPrimaryKey: result.zimFileID)
            cell.thumbImageView.image = UIImage(data: zimFile?.faviconData ?? Data()) ?? #imageLiteral(resourceName: "GenericZimFile")
            cell.thumbImageView.contentMode = .scaleAspectFit
        } catch {}
        
        cell.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        if let snippet = result.snippet {
            cell.detailLabel.attributedText = snippet
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let content = presentingViewController as? ContentController else {return}
        update(recentSearchText: searchText)
        content.load(url: results[indexPath.row].url)
        content.searchController.dismiss(animated: true)
        content.searchController.isActive = false
    }
}
