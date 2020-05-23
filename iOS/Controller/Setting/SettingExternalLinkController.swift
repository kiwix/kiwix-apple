//
//  SettingExternalLinkController.swift
//  iOS
//
//  Created by Chris Li on 2/20/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingExternalLinkController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    let loadingPolicies: [ExternalLinkLoadingPolicy] = [.alwaysLoad, .alwaysAsk, .neverLoad]
    private(set) var currentLoadingPolicy = ExternalLinkLoadingPolicy(rawValue: Defaults.externalLinkLoadingPolicy) ?? .alwaysAsk
    
    convenience init(title: String?) {
        self.init()
        self.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func loadView() {
        view = tableView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Defaults.externalLinkLoadingPolicy = currentLoadingPolicy.rawValue
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = loadingPolicies[indexPath.row].description
        cell.accessoryType = loadingPolicies[indexPath.row] == currentLoadingPolicy ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentLoadingPolicy = loadingPolicies[indexPath.row]
        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Loading Policy", comment: "Setting: External Link")
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("Decide if app should ask for permission to load an external link when Internet connection is required.", comment: "Setting: External Link")
    }
}

enum ExternalLinkLoadingPolicy: Int, CustomStringConvertible {
    case alwaysAsk = 0, alwaysLoad, neverLoad
    
    var description: String {
        switch self {
        case .alwaysAsk:
            return NSLocalizedString("Always ask", comment: "External Link Loading Policy")
        case .alwaysLoad:
            return NSLocalizedString("Always load without asking", comment: "External Link Loading Policy")
        case .neverLoad:
            return NSLocalizedString("Never load and don't ask", comment: "External Link Loading Policy")
        }
    }
}
