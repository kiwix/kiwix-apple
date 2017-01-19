//
//  SettingController.swift
//  Kiwix
//
//  Created by Chris Li on 1/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import UIKit
import MessageUI

class SettingController: UITableViewController {
    
    let rows = [[Localized.Setting.fontSize, Localized.Setting.notifications],
                [Localized.Setting.feedback, Localized.Setting.rateApp],
                [Localized.Setting.about]]

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
        cell.textLabel?.text = rows[indexPath.section][indexPath.row]
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let text = rows[indexPath.section][indexPath.row]
        switch text {
        case Localized.Setting.feedback:
            if MFMailComposeViewController.canSendMail() {
                UIQueue.shared.add(operation: FeedbackMailOperation(context: self))
            } else {
                UIQueue.shared.add(operation: EmailNotConfiguredAlert(context: self))
            }
        default:
            return
        }
    }

}

extension Localized {
    class Setting {
        static let title = NSLocalizedString("Setting", comment: "Setting view title")
        
        static let fontSize = NSLocalizedString("Font Size", comment: "Setting view rows")
        static let notifications = NSLocalizedString("Notifications", comment: "Setting view rows")
        
        static let feedback = NSLocalizedString("Email us your suggestions", comment: "Setting view rows")
        static let rateApp = NSLocalizedString("Give Kiwix a Rate", comment: "Setting view rows")
        
        static let about = NSLocalizedString("About", comment: "Setting view rows")
        
        class Feedback {
            static let subject = NSLocalizedString(String(format: "Feedback: Kiwix for iOS %@", Bundle.appShortVersion),
                                                   comment: "Feedback view subject, %@ will be replaced by kiwix version string")
            class Success {
                static let title = NSLocalizedString("Email Sent", comment: "Feedback success title")
                static let message = NSLocalizedString("Your Email was sent. We will get back to you shortly.", comment: "Feedback success message")
            }
            class NotConfiguredError {
                static let title = NSLocalizedString("Cannot send Email", comment: "Feedback error title")
                static let message = NSLocalizedString("The device is not configured to send email. You can send an email to chris@kiwix.org using other devices.", comment: "Feedback error message")
            }
            class ComposerError {
                static let title = NSLocalizedString("Email not sent", comment: "Feedback error title")
            }
        }
    }
}


