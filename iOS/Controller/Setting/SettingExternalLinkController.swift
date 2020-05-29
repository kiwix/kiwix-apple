//
//  SettingExternalLinkController.swift
//  Kiwix
//
//  Created by Chris Li on 2/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class SettingExternalLinkController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let loadingPolicies: [ExternalLinkLoadingPolicy] = [.alwaysLoad, .alwaysAsk, .neverLoad]
    
    convenience init(title: String?) {
        self.init()
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadingPolicies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let currentPolicy = loadingPolicies[indexPath.row]
        cell.textLabel?.text = currentPolicy.description
        cell.accessoryType = Defaults[.externalLinkLoadingPolicy] == currentPolicy ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let index = loadingPolicies.firstIndex(of: Defaults[.externalLinkLoadingPolicy]) else { return }
        let currentIndexPath = IndexPath(row: index, section: 0)
        guard currentIndexPath != indexPath else { return }
        Defaults[.externalLinkLoadingPolicy] = loadingPolicies[indexPath.row]
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.cellForRow(at: currentIndexPath)?.accessoryType = .none
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Loading Policy", comment: "Setting: External Link")
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("Decide if app should ask for permission to load an external link when Internet connection is required.", comment: "Setting: External Link")
    }
}
