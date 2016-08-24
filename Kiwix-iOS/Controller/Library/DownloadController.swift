//
//  DownloadController.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class DownloadController: UITableViewController {

    // MARK: - Override
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = ""
        tabBarItem.title = LocalizedStrings.LibraryTabTitle.download
        tabBarItem.image = UIImage(named: "Download")
        tabBarItem.selectedImage = UIImage(named: "DownloadFilled")
    }
    
}
