//
//  UIProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 1/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import MessageUI
import ProcedureKit

class FeedbackMailOperation: UIProcedure, MFMailComposeViewControllerDelegate {
    let controller = MFMailComposeViewController()
    
    init(context: UIViewController) {
        controller.setToRecipients(["chris@kiwix.org"])
        controller.setSubject(Localized.Setting.Feedback.subject)
        super.init(present: controller, from: context, withStyle: PresentationStyle.present, inNavigationController: false, finishAfterPresenting: false)
        controller.mailComposeDelegate = self
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let error = error {
            let alert = EmailNotSentAlert(context: controller, message: error.localizedDescription)
            alert.addDidFinishBlockObserver(block: { [weak self] (alert, errors) in
                self?.presented.dismiss(animated: true, completion: nil)
                self?.finish(withError: error)
            })
            try? produce(operation: alert)
        } else {
            guard result == .sent else {
                presented.dismiss(animated: true, completion: nil)
                finish()
                return
            }
            let alert = EmailSentAlert(context: controller)
            alert.addDidFinishBlockObserver(block: { [weak self] (alert, errors) in
                self?.presented.dismiss(animated: true, completion: nil)
                self?.finish()
            })
            try? produce(operation: alert)
        }
    }
}

class EmailSentAlert: UIProcedure {
    let controller = UIAlertController(title: Localized.Setting.Feedback.Success.title,
                                       message: Localized.Setting.Feedback.Success.message,
                                       preferredStyle: .alert)
    init(context: UIViewController) {
        super.init(present: controller, from: context, withStyle: .present, inNavigationController: false, finishAfterPresenting: false)
        controller.addAction(UIAlertAction(title: Localized.Alert.ok, style: .default, handler: {[weak self] _ in self?.finish()}))
    }
}

class EmailNotConfiguredAlert: UIProcedure {
    let controller = UIAlertController(title: Localized.Setting.Feedback.NotConfiguredError.title,
                                       message: Localized.Setting.Feedback.NotConfiguredError.message,
                                       preferredStyle: .alert)
    init(context: UIViewController) {
        super.init(present: controller, from: context, withStyle: .present, inNavigationController: false, finishAfterPresenting: false)
        controller.addAction(UIAlertAction(title: Localized.Alert.ok, style: .cancel, handler: {[weak self] _ in self?.finish()}))
    }
}

class EmailNotSentAlert: UIProcedure {
    let controller = UIAlertController(title: Localized.Setting.Feedback.ComposerError.title,
                                       message: nil,
                                       preferredStyle: .alert)
    init(context: UIViewController, message: String?) {
        controller.message = message
        super.init(present: controller, from: context, withStyle: .present, inNavigationController: false, finishAfterPresenting: false)
        controller.addAction(UIAlertAction(title: Localized.Alert.ok, style: .cancel, handler: {[weak self] _ in self?.finish()}))
    }
}

class RateKiwixAlert: UIProcedure {
    let controller = UIAlertController(title: nil, message: nil,
                                       preferredStyle: .alert)
//    init (context: UIViewController) {
//        
//    }
}
