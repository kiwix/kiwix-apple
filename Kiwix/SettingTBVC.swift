//
//  SettingTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SettingTBVC: UITableViewController {
    
    @IBOutlet weak var libraryAutoRefreshLabel: UILabel!
    @IBOutlet weak var downloadUseCellularDataLabel: UILabel!
    @IBOutlet weak var homePageLabel: UILabel!
    @IBOutlet weak var scalePageToFitWidthLabel: UILabel!
    @IBOutlet weak var fontSizeLabel: UILabel!
    
    let dateComponentsFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        return formatter
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        adjustForiPad()
        tableView.tableFooterView = tableFooterView(tableView.frame.width)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshTableViewCellLabels()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.tableFooterView = tableFooterView(size.width)
    }

    func adjustForiPad() {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.navigationController!.preferredContentSize = CGSizeMake(400, 500)
            self.edgesForExtendedLayout = .None
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    func refreshTableViewCellLabels() {
        libraryAutoRefreshLabel.text = dateComponentsFormatter.stringFromTimeInterval(Preference.libraryRefreshInterval)
        downloadUseCellularDataLabel.text = Preference.downloaderAllowCellularData ? "On" : "Off"
        homePageLabel.text = {
            if let webViewHomePage = Preference.webViewHomePage {
                switch webViewHomePage {
                case WebViewHomePage.Blank:
                    return "Blank"
                case WebViewHomePage.Random:
                    return "Random"
                case WebViewHomePage.MainPage:
                    if let idString = Preference.webViewHomePageBookID, let book = ZimMultiReader.sharedInstance.allLocalBooksInDataBase[idString] {
                        return book.title
                    }
                }
            }
            return "Not Set"
        }()
        scalePageToFitWidthLabel.text = Preference.webViewScalePageToFitWidth ? "On" : "Off"
        fontSizeLabel.text = String(format: "%.0f%%", Preference.webViewZoomScale)
    }
    
    func tableFooterView(width: CGFloat) -> UIView {
        let preferredWidth = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? self.navigationController!.preferredContentSize.width : width
        return Utilities.tableHeaderFooterView(withMessage: "Kiwix for iOS v1.1", preferredWidth: preferredWidth, textAlientment: .Center)
    }
    
    @IBAction func dismissSelf(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
