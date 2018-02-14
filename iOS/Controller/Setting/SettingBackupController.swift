//
//  SettingBackupController.swift
//  iOS
//
//  Created by Chris Li on 2/7/18.
//  Copyright © 2018 Chris Li. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingBackupController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    convenience init(title: String?) {
        self.init()
        self.title = title
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func loadView() {
        view = tableView
    }
    
    @objc func switchValueChanged(switchControl: UISwitch) {
        Defaults[.backupDocumentDirectory] = switchControl.isOn
        BackupManager.updateExcludedFromBackupForDocumentDirectoryContents(isExcluded: !Defaults[.backupDocumentDirectory])
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = NSLocalizedString("Zim files and indexes", comment: "Setting: Backup")
        cell.selectionStyle = .none
        let switchControl = UISwitch()
        switchControl.setOn(Defaults[.backupDocumentDirectory], animated: false)
        switchControl.addTarget(self, action: #selector(switchValueChanged(switchControl:)), for: .valueChanged)
        cell.accessoryView = switchControl
        return cell
    }
}
