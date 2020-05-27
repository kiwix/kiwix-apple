//
//  SettingSearchController.swift
//  Kiwix
//
//  Created by Chris Li on 6/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import Defaults
import SwiftyUserDefaults

class SettingSearchController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let snippetModes: [SearchResultSnippetMode] = {
        if #available(iOS 12.0, *) {
            return [.disabled, .firstParagraph, .firstSentence, .matches]
        } else {
            return [.disabled, .firstParagraph, .matches]
        }
    }()
    
    convenience init(title: String) {
        self.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return snippetModes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let mode = snippetModes[indexPath.row]
        cell.textLabel?.text = mode.description
        cell.accessoryType = mode == Defaults[.searchResultSnippetMode] ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let index = snippetModes.firstIndex(of: Defaults[.searchResultSnippetMode]) else { return }
        let currentIndexPath = IndexPath(row: index, section: 0)
        guard currentIndexPath != indexPath else { return }
        Defaults[.searchResultSnippetMode] = snippetModes[indexPath.row]
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.cellForRow(at: currentIndexPath)?.accessoryType = .none
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Snippets", comment: "Setting: Search")
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("If search is becoming too slow, disable the snippets to improve the situation.",
                                 comment: "Setting: Search")
    }
}
