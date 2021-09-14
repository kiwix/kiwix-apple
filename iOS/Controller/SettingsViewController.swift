//
//  SettingsViewController.swift
//  Kiwix
//
//  Created by Chris Li on 9/13/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import MessageUI
import SwiftUI

@available(iOS 13.0, *)
class SettingsViewController: UIHostingController<SettingsView>, MFMailComposeViewControllerDelegate {
    convenience init() {
        self.init(rootView: SettingsView())
        rootView.dismiss = { [unowned self] in self.dismiss(animated: true) }
        rootView.sendFeedback = { [unowned self] in self.presentFeedbackEmailComposer() }
    }
    
    private func presentFeedbackEmailComposer() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let controller = MFMailComposeViewController()
        controller.setToRecipients(["feedback@kiwix.org"])
        controller.setSubject("Feedback of Kiwix for iOS v\(version)")
        controller.mailComposeDelegate = self
        present(controller, animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
        switch result {
        case .sent:
            let alert = UIAlertController(
                title: NSLocalizedString("Email Sent", comment: "Feedback Email"),
                message: NSLocalizedString("We will read your message as soon as possible.", comment: "Feedback Email"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Feedback Email"), style: .default))
            present(alert, animated: true)
        case .failed:
            guard let error = error else {break}
            let alert = UIAlertController(
                title: NSLocalizedString("Email Not Sent", comment: "Feedback Email"),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Feedback Email"), style: .default))
            present(alert, animated: true)
        default:
            break
        }
    }
}
