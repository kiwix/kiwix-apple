//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
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
            UIQueue.shared.add(operation: AlertProcedure.rateKiwix(context: self, userInitiated: true))
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

extension Localized {
    class Setting {
        static let title = NSLocalizedString("Setting", comment: "Setting table title")
        
        static let fontSize = NSLocalizedString("Font Size", comment: "Setting table rows")
        static let notifications = NSLocalizedString("Notifications", comment: "Setting table rows")
        static let feedback = NSLocalizedString("Email us your suggestions", comment: "Setting table rows")
        static let rateApp = NSLocalizedString("Give Kiwix a Rate", comment: "Setting table rows")
        static let about = NSLocalizedString("About", comment: "Setting table rows")
        static let version = NSLocalizedString("Kiwix for iOS v%@", comment: "Setting table footer")
        
        class Notifications {
            static let libraryRefresh = NSLocalizedString("Library Refresh", comment: "Notification Setting")
            static let bookUpdateAvailable = NSLocalizedString("Book Update Available", comment: "Notification Setting")
        }
        
        class Feedback {
            static let subject = NSLocalizedString(String(format: "Feedback: Kiwix for iOS %@", Bundle.appShortVersion),
                                                   comment: "Feedback email composer subject, %@ will be replaced by kiwix version string")
            class Success {
                static let title = NSLocalizedString("Email Sent", comment: "Feedback success title")
                static let message = NSLocalizedString("Your Email was sent successfully.", comment: "Feedback success message")
            }
            class NotConfiguredError {
                static let title = NSLocalizedString("Cannot send Email", comment: "Feedback error title")
                static let message = NSLocalizedString("The device is not configured to send email. You can send an email to chris@kiwix.org using other devices.", comment: "Feedback error message")
            }
            class ComposerError {
                static let title = NSLocalizedString("Email not sent", comment: "Feedback error title")
            }
        }
        
        class RateApp {
            static let message = NSLocalizedString("Would you like to rate Kiwix in App Store?", comment: "Rate app alert message")
            static let goToAppStore = NSLocalizedString("Go to App Store", comment: "Rate app alert action")
            static let remindMeLater = NSLocalizedString("Remind Me Later", comment: "Rate app alert action")
        }
    }
}


