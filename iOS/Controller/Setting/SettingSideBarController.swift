//
//  SettingSideBarController.swift
//  Kiwix
//
//  Created by Chris Li on 5/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class SettingSideBarController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let displayModes: [SideBarDisplayMode] = [.automatic, .overlay, .sideBySide]
    
    convenience init(title: String) {
        self.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.isScrollEnabled = false
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayModes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let mode = displayModes[indexPath.row]
        cell.textLabel?.text = mode.description
        cell.accessoryType = Defaults[.sideBarDisplayMode] == mode ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let index = displayModes.firstIndex(of: Defaults[.sideBarDisplayMode]) else { return }
        let currentIndexPath = IndexPath(row: index, section: 0)
        guard currentIndexPath != indexPath else { return }
        Defaults[.sideBarDisplayMode] = displayModes[indexPath.row]
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.cellForRow(at: currentIndexPath)?.accessoryType = .none
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Display Mode"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString(
            "Controls how side bar is displayed when the toggle sidebar button is tapped.", comment: "Sidebar setting"
        )
    }
}
