//
//  SettingLibraryController.swift
//  iOS
//
//  Created by Chris Li on 7/16/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingLibraryController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    let sections: [MenuItem] = [.lastRefresh, .refreshNow]
    
    var lastRefreshTimeFormatted: String {
        guard let lastRefreshTime = Defaults[.libraryLastRefreshTime] else {return "Unknown"}
        print(lastRefreshTime)
        
        let components = Calendar.current.dateComponents([.year, .month, .weekOfMonth, .day, .hour, .minute, .second], from: lastRefreshTime, to: Date())
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        if let year = components.year, year > 0 {
            formatter.allowedUnits = .year
        } else if let month = components.month, month > 0 {
            formatter.allowedUnits = .month
        } else if let week = components.weekOfMonth, week > 0 {
            formatter.allowedUnits = .weekOfMonth
        } else if let day = components.day, day > 0 {
            formatter.allowedUnits = .day
        } else if let hour = components.hour, hour > 0 {
            formatter.allowedUnits = [.hour]
        } else if let minute = components.minute, minute > 0 {
            formatter.allowedUnits = .minute
        } else {
            formatter.allowedUnits = .second
        }
        
        guard let formatted = formatter.string(from: components) else {return "Unknown"}
        return NSLocalizedString(String(format: "%@ ago", formatted), comment: "")
    }
    
    convenience init(title: String?) {
        self.init()
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.register(UIRightDetailTableViewCell.self, forCellReuseIdentifier: "RightDetailCell")
        tableView.register(UIActionTableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section]
        switch item {
        case .lastRefresh:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetailCell") as! UIRightDetailTableViewCell
            cell.textLabel?.text = item.description
            cell.detailTextLabel?.text = lastRefreshTimeFormatted
            return cell
        case .refreshNow:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell") as! UIActionTableViewCell
            cell.textLabel?.text = item.description
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    enum MenuItem: CustomStringConvertible {
        case lastRefresh, refreshNow
        
        var description: String {
            switch self {
            case .lastRefresh:
                return NSLocalizedString("Last Refresh", comment: "Setting Item Title")
            case .refreshNow:
                return NSLocalizedString("Refresh Now", comment: "Setting Item Title")
            }
        }
    }

}
