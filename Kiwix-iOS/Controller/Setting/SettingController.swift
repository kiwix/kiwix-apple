//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import StoreKit
import MessageUI
import ProcedureKit

class SettingController: UITableViewController {
    
    let rows = [[Localized.Setting.fontSize, Localized.Setting.notifications],
                [Localized.Setting.feedback, Localized.Setting.rateApp],
                [Localized.Setting.about]]
    
    let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.maximumIntegerDigits = 3
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.Setting.title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let text = rows[indexPath.section][indexPath.row]
        cell.textLabel?.text = text
        switch text {
        case Localized.Setting.fontSize:
            cell.detailTextLabel?.text = percentageFormatter.string(from: NSNumber(value: Preference.webViewZoomScale))
        default:
            cell.detailTextLabel?.text = nil
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let text = rows[indexPath.section][indexPath.row]
        switch text {
        case Localized.Setting.fontSize:
            let controller = UIStoryboard(name: "Setting", bundle: nil).instantiateViewController(withIdentifier: "FontSizeController") as! FontSizeController
            controller.title = Localized.Setting.fontSize
            navigationController?.pushViewController(controller, animated: true)
        case Localized.Setting.notifications:
            let controller = UIStoryboard(name: "Setting", bundle: nil).instantiateViewController(withIdentifier: "NotificationSettingController") as! NotificationSettingController
            controller.title = Localized.Setting.notifications
            navigationController?.pushViewController(controller, animated: true)
        case Localized.Setting.feedback:
            if MFMailComposeViewController.canSendMail() {
                UIQueue.shared.add(operation: FeedbackMailOperation(context: self))
            } else {
                UIQueue.shared.add(operation: AlertProcedure.Feedback.emailNotConfigured(context: self))
            }
        case Localized.Setting.rateApp:
            if #available(iOS 10.3, OSX 10.12.4, *) {
                SKStoreReviewController.requestReview()
            } else {
                UIQueue.shared.add(operation: AlertProcedure.rateKiwix(context: self))
            }
        case Localized.Setting.about:
            let controller = UIStoryboard(name: "Setting", bundle: nil).instantiateViewController(withIdentifier: "StaticWebController") as! StaticWebController
            controller.title = Localized.Setting.about
            controller.load(htmlFileName: "About")
            navigationController?.pushViewController(controller, animated: true)
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {return nil}
        return String(format: Localized.Setting.version, Bundle.appShortVersion)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == tableView.numberOfSections - 1 else {return}
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textAlignment = .center
        }
    }

}

