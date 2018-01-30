//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SettingNavigationController: UINavigationController {
    convenience init() {
        self.init(rootViewController: SettingController())
        modalPresentationStyle = .formSheet
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }
}

class SettingController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let items: [[SettingMenuItem]] = [
        [.about(NSLocalizedString("About", comment: "Setting Item Title"))]
    ]
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "Setting title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissController))
    }
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .about(let title):
            cell.textLabel?.text = title
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .about(let title):
            guard let path = Bundle.main.path(forResource: "About", ofType: "html") else {return}
            let url = URL(fileURLWithPath: path)
            let controller = SettingWebController(fileURL: url)
            controller.title = title
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
}

enum SettingMenuItem {
    case about(String)
}
