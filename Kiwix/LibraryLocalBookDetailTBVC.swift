//
//  LibraryLocalBookDetailTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class LibraryLocalBookDetailTBVC: UITableViewController {

    var book: Book?
    let sections = [LocalizedStrings.info, LocalizedStrings.file]
    let titles = [[LocalizedStrings.title, LocalizedStrings.creationDate, LocalizedStrings.articleCount, LocalizedStrings.mediaCount],
                  [LocalizedStrings.size, LocalizedStrings.fileName]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = book?.title
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.toolbarHidden = false
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return book == nil ? 0 : sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        cell.textLabel?.text = titles[indexPath.section][indexPath.row]
        cell.detailTextLabel?.text = "placehold"

        return cell
    }
}

extension LocalizedStrings {
    class var info: String {return NSLocalizedString("Info", comment: "Book Detail")}
    class var title: String {return NSLocalizedString("Title", comment: "Book Detail")}
    class var creationDate: String {return NSLocalizedString("Creation Date", comment: "Book Detail")}
    class var articleCount: String {return NSLocalizedString("Article Count", comment: "Book Detail")}
    class var mediaCount: String {return NSLocalizedString("Media Count", comment: "Book Detail")}
    
    class var file: String {return NSLocalizedString("File", comment: "Book Detail")}
    class var size: String {return NSLocalizedString("size", comment: "Book Detail")}
    class var fileName: String {return NSLocalizedString("File Name", comment: "Book Detail")}
}
