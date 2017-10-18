//
//  LibraryBookDetailController.swift
//  iOS
//
//  Created by Chris Li on 10/17/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit

class LibraryBookDetailController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private(set) var book: Book?
    let tableView = UITableView(frame: .zero, style: .grouped)
    let titles = [
        [NSLocalizedString("Delete File", comment: "Book Detail Cell"), NSLocalizedString("Delete Bookmarks", comment: "Book Detail Cell"), NSLocalizedString("Delete File and Bookmarks", comment: "Book Detail Cell")],
        [NSLocalizedString("Size", comment: "Book Detail Cell"), NSLocalizedString("Date", comment: "Book Detail Cell")]
    ]
    
    convenience init(book: Book) {
        self.init()
        self.book = book
        title = book.title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActionCell")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath)
            cell.textLabel?.text = titles[indexPath.section][indexPath.row]
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "Cell")
            cell.textLabel?.text = titles[indexPath.section][indexPath.row]
            cell.selectionStyle = .none
            switch (indexPath.section, indexPath.row) {
            case (1,0):
                cell.detailTextLabel?.text = book?.fileSizeDescription
            case (1,1):
                cell.detailTextLabel?.text = book?.dateDescription
            default:
                break
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: "Book Delete Confirmation"), message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive, handler: { _ in
                print("book delete")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        }
    }
}


