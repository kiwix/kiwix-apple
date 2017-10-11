//
//  LibraryController.swift
//  Kiwix
//
//  Created by Chris Li on 10/10/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryController: UISplitViewController, UISplitViewControllerDelegate {
    let master  = LibraryMasterController()
    let detail = UITableViewController()
    init() {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [
            UINavigationController(rootViewController: master),
            UINavigationController(rootViewController: detail)
        ]
        delegate = self
        preferredDisplayMode = .allVisible
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

class LibraryMasterController: BaseController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let categories = [
        NSLocalizedString("Wikipedia", comment: "Zim Types"),
        NSLocalizedString("WikiMedicine", comment: "Zim Types"),
        NSLocalizedString("Wikivoyage", comment: "Zim Types"),
        NSLocalizedString("Wikibooks", comment: "Zim Types"),
        NSLocalizedString("Wikiversity", comment: "Zim Types"),
        NSLocalizedString("Wikispecies", comment: "Zim Types"),
        NSLocalizedString("Wikinews", comment: "Zim Types"),
        NSLocalizedString("Vikidia", comment: "Zim Types"),
        NSLocalizedString("TED", comment: "Zim Types"),
        NSLocalizedString("StackExchange", comment: "Zim Types"),
        NSLocalizedString("Gutenberg", comment: "Zim Types"),
        NSLocalizedString("Phet", comment: "Zim Types"),
    ]
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Library", comment: "Library title")
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 3
        case 2:
            return categories.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Downloading Book Title"
        case 1:
            cell.textLabel?.text = "Local Book Title"
        case 2:
            cell.textLabel?.text = categories[indexPath.row]
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Downloading"
        case 1:
            return "On Device"
        case 2:
            return "Categories"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
