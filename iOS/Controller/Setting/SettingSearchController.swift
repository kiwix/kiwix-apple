//
//  SettingSearchController.swift
//  Kiwix
//
//  Created by Chris Li on 6/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingSearchController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let snippetModeOptions: [SearchResultSnippetMode] = {
        if #available(iOS 12.0, *) {
            return [.disabled, .firstParagraph, .firstSentence, .matches]
        } else {
            return [.disabled, .firstParagraph, .matches]
        }
    }()
    
    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        return snippetModeOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mode = snippetModeOptions[indexPath.row]
        let currentMode = SearchResultSnippetMode(rawValue: Defaults.searchResultSnippetMode)
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = mode.description
        cell.accessoryType = mode == currentMode ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        guard let currentMode = SearchResultSnippetMode(rawValue: Defaults.searchResultSnippetMode),
            let index = snippetModeOptions.firstIndex(of: currentMode) else { return }
        tableView.cellForRow(at: IndexPath(row: index, section: 0))?.accessoryType = .none
        Defaults.searchResultSnippetMode = snippetModeOptions[indexPath.row].rawValue
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Snippets", comment: "Setting: Search")
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("If search is becoming too slow, disable the snippets to improve the situation.",
                                 comment: "Setting: Search")
    }
}
