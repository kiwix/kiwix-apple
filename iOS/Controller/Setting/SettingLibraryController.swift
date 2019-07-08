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
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let items: [[MenuItem]] = [[.refreshNow], [.languageFilter]]
    private var timer: Timer?
    
    var lastRefreshTimeFormatted: String {
        let unknown = NSLocalizedString("Unknown", comment: "Library refresh time, unknown")
        guard let lastRefreshTime = Defaults[.libraryLastRefreshTime] else { return unknown }
        
        if lastRefreshTime.timeIntervalSinceNow * -1 > 60 {
            let components = Calendar.current.dateComponents([.year, .month, .weekOfMonth, .day, .hour, .minute, .second],
                                                             from: lastRefreshTime, to: Date())
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
            
            guard let formatted = formatter.string(from: components) else { return unknown }
            return NSLocalizedString(String(format: "%@ ago", formatted), comment: "Library refresh time")
        } else {
            return NSLocalizedString("Just now", comment: "Library refresh time")
        }
    }
    
    // MARK: - Override
    
    convenience init(title: String?) {
        self.init()
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UIActionTableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.register(UIRightDetailTableViewCell.self, forCellReuseIdentifier: "RightDetailCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
        }
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .refreshNow:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell") as! UIActionTableViewCell
//            if Queue.shared.isRefreshingLibrary {
//                cell.textLabel?.text = NSLocalizedString("Refreshing...", comment: "Setting Item Title")
//                cell.isDisabled = true
//                cell.isUserInteractionEnabled = false
//            } else {
//                cell.textLabel?.text = NSLocalizedString("Refresh Now", comment: "Setting Item Title")
//                cell.isDisabled = false
//                cell.isUserInteractionEnabled = true
//            }
            return cell
        case .languageFilter:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.textLabel?.text = NSLocalizedString("Language Filter", comment: "Setting Item Title")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let label = UITableViewSectionFooterLabel()
            label.text = String(format: NSLocalizedString("Last refresh: %@", comment: ""), lastRefreshTimeFormatted)
            return label
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 30 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.section][indexPath.row]
        switch item {
        case .refreshNow:
            break
        case .languageFilter:
            let controller = LibraryLanguageController()
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Type Definition
    
    enum MenuItem {
        case refreshNow, languageFilter
    }
}
