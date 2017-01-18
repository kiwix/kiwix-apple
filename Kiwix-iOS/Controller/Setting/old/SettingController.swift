//
//  SettingTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class SettingTBVC: UITableViewController {
    fileprivate(set) var sectionHeader: [String?] = [nil, LocalizedStrings.misc]
    fileprivate(set) var cellTitles = [[LocalizedStrings.backupLocalFiles, LocalizedStrings.fontSize, LocalizedStrings.searchHistory],
                          [LocalizedStrings.rateKiwix, LocalizedStrings.about]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.settings
        clearsSelectionOnViewWillAppear = true
        showRateKiwixIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return cellTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let title = cellTitles[indexPath.section][indexPath.row]
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = {
            switch title {
            case LocalizedStrings.backupLocalFiles:
                guard let skipBackup = FileManager.getSkipBackupAttribute(item: FileManager.docDirURL) else {return ""}
                return skipBackup ? LocalizedStrings.off: LocalizedStrings.on
            case LocalizedStrings.fontSize:
                return String.formattedPercentString(Preference.webViewZoomScale / 100)
            default:
                return nil
            }
        }()
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeader[section]
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {return nil}
        var footnote = String(format: LocalizedStrings.settingFootnote, Bundle.appShortVersion)
        switch UIApplication.buildStatus {
        case .alpha, .beta:
            footnote += (UIApplication.buildStatus == .alpha ? " Alpha" : " Beta")
            footnote += "\n"
            footnote += "Build " + Bundle.buildVersion
            return footnote
        case .release:
            return footnote
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == tableView.numberOfSections - 1 else {return}
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {tableView.deselectRow(at: indexPath, animated: true)}
        let cell = tableView.cellForRow(at: indexPath)
        guard let text = cell?.textLabel?.text else {return}
        switch text {
        case LocalizedStrings.backupLocalFiles:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewController(withIdentifier: "SettingDetailController") as! SettingDetailController
            controller.page = .BackupLocalFiles
            navigationController?.pushViewController(controller, animated: true)
        case LocalizedStrings.searchHistory:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewController(withIdentifier: "SettingDetailController") as! SettingDetailController
            controller.page = .SearchHistory
            navigationController?.pushViewController(controller, animated: true)
        case LocalizedStrings.fontSize:
            let controller = UIStoryboard(name: "Setting", bundle: nil)
                .instantiateViewController(withIdentifier: "FontSizeController") as! FontSizeController
            navigationController?.pushViewController(controller, animated: true)
        case LocalizedStrings.rateKiwix:
            showRateKiwixAlert(showRemindLater: false)
        case LocalizedStrings.about:
            break
//            let controller = UIStoryboard(name: "Setting", bundle: nil)
//                .instantiateViewController(withIdentifier: "WebViewControllerOld") as! WebViewControllerOld
//            controller.page = .About
//            navigationController?.pushViewController(controller, animated: true)
        default:
            break
        }
    }
    
    // MARK: - Rate Kiwix
    
    func showRateKiwixIfNeeded() {
        guard Preference.haveRateKiwix == false else {return}
        guard let firstActiveDate = Preference.activeUseHistory.first else {return}
        let installtionIsOldEnough = Date().timeIntervalSince(firstActiveDate as Date) > 3600.0 * 24 * 7
        let hasActivelyUsed = Preference.activeUseHistory.count > 10
        if installtionIsOldEnough && hasActivelyUsed {
            showRateKiwixAlert(showRemindLater: true)
        }
    }
    
    func showRateKiwixAlert(showRemindLater: Bool) {
        let alert = UIAlertController(title: LocalizedStrings.rateKiwixTitle, message: LocalizedStrings.rateKiwixMessage, preferredStyle: .alert)
        let remindLater = UIAlertAction(title: LocalizedStrings.rateLater, style: .default) { (action) -> Void in
            Preference.activeUseHistory.removeAll()
        }
        let remindNever = UIAlertAction(title: LocalizedStrings.rateNever, style: .default) { (action) -> Void in
            Preference.haveRateKiwix = true
        }
        let rateNow = UIAlertAction(title: LocalizedStrings.rateNow, style: .cancel) { (action) -> Void in
            self.goRateInAppStore()
            Preference.haveRateKiwix = true
        }
        let cancel = UIAlertAction(title: LocalizedStrings.cancel, style: .default, handler: nil)
        
        if showRemindLater {
            alert.addAction(remindLater)
            alert.addAction(remindNever)
            alert.addAction(rateNow)
        } else {
            alert.addAction(rateNow)
            alert.addAction(cancel)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func goRateInAppStore() {
//        let url = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=997079563&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8")!
//        UIApplication.shared.openURL(url)
    }
    
    // MARK: - Actions
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension LocalizedStrings {
    static let settings = NSLocalizedString("Settings", comment: "Settings")
    
    static let backupLocalFiles = NSLocalizedString("Backup Local Files", comment: "Setting")
    static let fontSize = NSLocalizedString("Font Size", comment: "Setting")
    static let searchHistory = NSLocalizedString("Search History", comment: "Setting")
    
    static let misc = NSLocalizedString("Misc", comment: "Setting")
    static let rateKiwix = NSLocalizedString("Give Kiwix a rate!", comment: "Setting")
    static let about = NSLocalizedString("About", comment: "Setting")
    static let settingFootnote = NSLocalizedString("Kiwix for iOS v%@", comment: "Version footnote (please translate 'v' as version)")
    
    //MARK: -  Rate Kiwix
    class var rateKiwixTitle: String {return NSLocalizedString("Give Kiwix a rate!", comment: "Rate Kiwix in App Store Alert Title")}
    class var rateNow: String {return NSLocalizedString("Rate Now", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateLater: String {return NSLocalizedString("Remind me later", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateNever: String {return NSLocalizedString("Never remind me again", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateKiwixMessage: String {return NSLocalizedString("We hope you enjoyed using Kiwix so far. Would you like to give us a rate in App Store?", comment: "Rate Kiwix in App Store Alert Message")}
}
