//
//  SettingSearchController.swift
//  iOS
//
//  Created by Chris Li on 6/12/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingSearchController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
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
    
    @objc func switchValueChanged(switchControl: UISwitch) {
        Defaults[.searchResultExcludeSnippet] = !switchControl.isOn
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = NSLocalizedString("Snippet", comment: "Setting: Search")
        cell.selectionStyle = .none
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
        switchControl.isOn = !Defaults[.searchResultExcludeSnippet]
        cell.accessoryView = switchControl
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Search Result", comment: "Setting: Search")
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("If search performance issue is encountered, disable snippets to improve the situation.", comment: "Setting: Search")
    }
    
}

extension DefaultsKeys {
    static let searchResultExcludeSnippet = DefaultsKey<Bool>("searchResultExcludeSnippet")
}
