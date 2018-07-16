//
//  SettingLibraryController.swift
//  iOS
//
//  Created by Chris Li on 7/16/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit

class SettingLibraryController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    convenience init(title: String?) {
        self.init()
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func configureRefreshTokenTitle() {
//        guard let lastRefreshTime = Defaults[.libraryLastRefreshTime] else {return}
        
//        let components = Calendar.current.dateComponents([.year, .month, .weekOfMonth, .day, .hour, .minute, .second], from: lastRefreshTime, to: Date())
//        let formatter = DateComponentsFormatter()
//        formatter.unitsStyle = .full
//        if let year = components.year, year > 0 {
//            formatter.allowedUnits = .year
//        } else if let month = components.month, month > 0 {
//            formatter.allowedUnits = .month
//        } else if let week = components.weekOfMonth, week > 0 {
//            formatter.allowedUnits = .weekOfMonth
//        } else if let day = components.day, day > 0 {
//            formatter.allowedUnits = .day
//        } else if let hour = components.hour, hour > 0 {
//            formatter.allowedUnits = [.hour]
//        } else if let minute = components.minute, minute > 0 {
//            formatter.allowedUnits = .minute
//        } else {
//            formatter.allowedUnits = .second
//        }
//
//        guard let formatted = formatter.string(from: components) else {return}
//        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString(
//            String(format: "Last refresh: %@ ago", formatted), comment: "Time elapsed since last library refresh"))
    }
    
    enum MenuItem: CustomStringConvertible {
        case lastRefreshTimeStamp, lastRefreshAgo
        
        var description: String {
            switch self {
            case .lastRefreshTimeStamp:
                return NSLocalizedString("Backup", comment: "Setting Item Title")
            case .lastRefreshAgo:
                return NSLocalizedString("External Link", comment: "Setting Item Title")
            }
        }
    }

}
