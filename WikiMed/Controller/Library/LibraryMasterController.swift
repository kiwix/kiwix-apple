//
//  LibraryMasterController.swift
//  Kiwix
//
//  Created by Chris Li on 10/12/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryMasterController: BaseController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let categories: [BookCategory] = [
        .wikipedia, .wikivoyage, .wikibooks, .wikiversity, .wikispecies, .wikinews,
        .vikidia, .ted, .stackExchange, .gutenberg, .other]
    let categoryImages = [#imageLiteral(resourceName: "Wikipedia"), #imageLiteral(resourceName: "Wikivoyage"), #imageLiteral(resourceName: "Wikibooks"), #imageLiteral(resourceName: "Wikiversity"), #imageLiteral(resourceName: "Wikispecies"), #imageLiteral(resourceName: "Wikinews"), #imageLiteral(resourceName: "Vikidia"), #imageLiteral(resourceName: "TED"), #imageLiteral(resourceName: "StackExchange"), #imageLiteral(resourceName: "Gutenberg"), #imageLiteral(resourceName: "Other")]
    let categoryNames = [
        NSLocalizedString("Wikipedia", comment: "Zim File Types"),
        NSLocalizedString("Wikivoyage", comment: "Zim File Types"),
        NSLocalizedString("Wikibooks", comment: "Zim File Types"),
        NSLocalizedString("Wikiversity", comment: "Zim File Types"),
        NSLocalizedString("Wikispecies", comment: "Zim File Types"),
        NSLocalizedString("Wikinews", comment: "Zim File Types"),
        NSLocalizedString("Vikidia", comment: "Zim File Types"),
        NSLocalizedString("TED", comment: "Zim File Types"),
        NSLocalizedString("StackExchange", comment: "Zim File Types"),
        NSLocalizedString("Gutenberg", comment: "Zim File Types"),
        NSLocalizedString("Other", comment: "Zim File Types")]
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(LibraryCategoryCell.self, forCellReuseIdentifier: "CategoryCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Library", comment: "Library title")
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
    }
    
    // MARK: - UITableViewDataSource & Delegates
    
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
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "Downloading Book Title"
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "Local Book Title"
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath) as! LibraryCategoryCell
            cell.accessoryType = .disclosureIndicator
            cell.titleLabel.text = categoryNames[indexPath.row]
            cell.logoView.image = categoryImages[indexPath.row]
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Downloading", comment: "Library section headers")
        case 1:
            return NSLocalizedString("On Device", comment: "Library section headers")
        case 2:
            return NSLocalizedString("Categories", comment: "Library section headers")
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let split = splitViewController as? LibraryController {
            split.detail.prepare(category: categories[indexPath.row], name: categoryNames[indexPath.row])
            showDetailViewController(UINavigationController(rootViewController: split.detail), sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

