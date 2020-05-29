//
//  LibrarySettingController.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit
import Defaults

class SettingLibraryController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Section { case updateAction, updateConfig, backup }
    private enum Row { case manualUpdate, lastUpdateTimestamp, scheduledUpdateEnabled, backupEnabled }
    
    private let tableView = UITableView(frame: .zero, style: {
        if #available(iOS 13, *) {
            return .insetGrouped
        } else {
            return .grouped
        }
    }())
    private let sections: [Section] = [.updateAction, .updateConfig, .backup]
    private let rows: [[Row]] = [[.manualUpdate], [.lastUpdateTimestamp, .scheduledUpdateEnabled], [.backupEnabled]]
    private var operationFinished = true
    private var contentSizeObserver : NSKeyValueObservation?
    private var refreshOperationFinishedObserver: NSKeyValueObservation?

    // MARK: - Override
    
    convenience init(title: String) {
        self.init(nibName: nil, bundle: nil)
        self.title = title
    }
    
    override func loadView() {
        view = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UIActionTableViewCell.self, forCellReuseIdentifier: "ActionCell")
        tableView.register(UIRightDetailTableViewCell.self, forCellReuseIdentifier: "DetailCell")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Info", comment: "Library Info")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismissController)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentSizeObserver = tableView.observe(\.contentSize) { [unowned self] tableView, _ in
            self.preferredContentSize = tableView.contentSize
        }
        if let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation {
            operationFinished = operation.isFinished
            configureOperationFinishedObserver(operation: operation)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contentSizeObserver = nil
    }
    
    private func configureOperationFinishedObserver(operation: OPDSRefreshOperation) {
        refreshOperationFinishedObserver = operation.observe(
            \.isFinished, options: .new
        ) { [weak self] (operation, _) in
            DispatchQueue.main.sync {
                self?.operationFinished = operation.isFinished
                self?.tableView.reloadSections([0, 1], with: .automatic)
            }
        }
    }
    
    // MARK: - UIControl Actions
    
    @objc func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func toggleAutoRefresh() {
        Defaults[.libraryAutoRefresh] = !Defaults[.libraryAutoRefresh]
    }
    
    @objc func toggleBackupDocumentDirectory() {
        Defaults[.backupDocumentDirectory] = !Defaults[.backupDocumentDirectory]
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
    }
    
    // MARK: - UITableViewDataSource & Delegates

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.section][indexPath.row] {
        case .manualUpdate:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as! UIActionTableViewCell
            cell.isDestructive = false
            if operationFinished {
                cell.textLabel?.text = "Update Now"
                cell.isDisabled = false
            } else {
                cell.textLabel?.text = "Updating..."
                cell.isDisabled = true
            }
            return cell
        case .lastUpdateTimestamp:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! UIRightDetailTableViewCell
            cell.textLabel?.text = "Last updated"
            if let refreshTime = Defaults[.libraryLastRefreshTime] {
                if Date().timeIntervalSince(refreshTime) < 120 {
                    cell.detailTextLabel?.text = NSLocalizedString("Just now", comment: "Library Info")
                } else if #available(iOS 13.0, *) {
                    let formatter = RelativeDateTimeFormatter()
                    cell.detailTextLabel?.text = formatter.localizedString(for: refreshTime, relativeTo: Date())
                } else {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    cell.detailTextLabel?.text = formatter.string(from: refreshTime)
                }
            } else {
                cell.detailTextLabel?.text = NSLocalizedString("Never", comment: "Library Info")
            }
            
            return cell
        case .scheduledUpdateEnabled:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! UIRightDetailTableViewCell
            cell.textLabel?.text = "Auto updates"
            cell.accessoryView = {
                let toggle = UISwitch()
                toggle.isOn = Defaults[.libraryAutoRefresh]
                toggle.addTarget(self, action: #selector(toggleAutoRefresh), for: .valueChanged)
                return toggle
            }()
            return cell
        case .backupEnabled:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! UIRightDetailTableViewCell
            cell.textLabel?.text = "Include zim files in backup"
            cell.accessoryView = {
                let toggle = UISwitch()
                toggle.isOn = Defaults[.backupDocumentDirectory]
                toggle.addTarget(self, action: #selector(toggleBackupDocumentDirectory), for: .valueChanged)
                return toggle
            }()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath == IndexPath(row: 0, section: 0) else { return }
        operationFinished = false
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        
        let operation: OPDSRefreshOperation = {
            if let operation = LibraryOperationQueue.shared.currentOPDSRefreshOperation {
                return operation
            } else {
                let operation = OPDSRefreshOperation(updateExisting: true)
                LibraryOperationQueue.shared.addOperation(operation)
                return operation
            }
        }()
        configureOperationFinishedObserver(operation: operation)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .updateAction:
            return NSLocalizedString("Catalog", comment: "Library Info Section")
        case .backup:
            return NSLocalizedString("Backup", comment: "Library Info Section")
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sections[section] {
        case .updateConfig:
            return NSLocalizedString("""
            When enabled, the library catalog will be updated both when library is opened \
            and utilizing iOS's Background App Refresh feature.
            """, comment: "Library Info")
        case .backup:
            return NSLocalizedString("Does not apply to files that were opened in place.", comment: "Library Info") + "\n"
        default:
            return nil
        }
    }
}
