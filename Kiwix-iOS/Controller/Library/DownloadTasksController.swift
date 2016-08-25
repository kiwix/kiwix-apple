//
//  DownloadController.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class DownloadTasksController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = ""
        tabBarItem.title = LocalizedStrings.LibraryTabTitle.download
        tabBarItem.image = UIImage(named: "Download")
        tabBarItem.selectedImage = UIImage(named: "DownloadFilled")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }
    
}
