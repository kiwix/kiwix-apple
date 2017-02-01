//
//  UIProcedure.swift
//  Kiwix
//
//  Created by Chris Li on 1/18/17.
//  Copyright © 2017 Chris Li. All rights reserved.
//

import MessageUI
import ProcedureKit

// MARK: - Feedback

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
            let alert = AlertProcedure.Feedback.emailNotSent(context: controller, message: error.localizedDescription)
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
            let alert = AlertProcedure.Feedback.emailSent(context: controller)
            alert.addDidFinishBlockObserver(block: { [weak self] (alert, errors) in
                self?.presented.dismiss(animated: true, completion: nil)
                self?.finish()
            })
            try? produce(operation: alert)
        }
    }
}

extension AlertProcedure {
    class Feedback {
        static func emailSent(context: UIViewController) -> AlertProcedure {
            let alert = AlertProcedure(presentAlertFrom: context)
            alert.title = Localized.Setting.Feedback.Success.title
            alert.message = Localized.Setting.Feedback.Success.message
            alert.add(actionWithTitle: Localized.Common.ok, style: .default)
            return alert
        }
        
        static func emailNotConfigured(context: UIViewController) -> AlertProcedure {
            let alert = AlertProcedure(presentAlertFrom: context)
            alert.title = Localized.Setting.Feedback.NotConfiguredError.title
            alert.message = Localized.Setting.Feedback.NotConfiguredError.message
            alert.add(actionWithTitle: Localized.Common.ok, style: .cancel)
            return alert
        }
        
        static func emailNotSent(context: UIViewController, message: String?) -> AlertProcedure {
            let alert = AlertProcedure(presentAlertFrom: context)
            alert.title = Localized.Setting.Feedback.ComposerError.title
            alert.message = message
            alert.add(actionWithTitle: Localized.Common.ok, style: .cancel)
            return alert
        }
    }
    
    static func rateKiwix(context: UIViewController, userInitiated: Bool) -> AlertProcedure {
        let alert = AlertProcedure(presentAlertFrom: context)
        alert.title = Localized.Setting.rateApp
        alert.message = Localized.Setting.RateApp.message
        alert.add(actionWithTitle: Localized.Setting.RateApp.goToAppStore, style: .default) { _ in
            let url = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=997079563&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        if !userInitiated {
            alert.add(actionWithTitle: Localized.Setting.RateApp.remindMeLater, style: .default, handler: { (alert, action) in
                // clear launch history
            })
        }
        alert.add(actionWithTitle: Localized.Common.cancel, style: .cancel)
        return alert
    }
    
    static func bookMore(context: UIViewController, book: Book) -> AlertProcedure {
        assert(Thread.isMainThread, "The more")
        let alert = AlertProcedure(presentAlertFrom: context, withPreferredStyle: .actionSheet, waitForDismissal: true)
        alert.title = book.title
        if book.state == .cloud {
            alert.add(actionWithTitle: Localized.Library.download, style: .default) { _ in
                Network.shared.start(bookID: book.id)
                alert.finish()
            }
            alert.add(actionWithTitle: Localized.Library.copyURL, style: .default) { _ in
                guard let url = book.url else {return}
                UIPasteboard.general.string = url.absoluteString
                alert.finish()
            }
        } else if book.state == .local {
            alert.add(actionWithTitle: "set back to cloud", style: .default) { _ in
                let context = AppDelegate.persistentContainer.viewContext
                context.perform({
                    book.state = .cloud
                })
                alert.finish()
            }
        }
        
        alert.add(actionWithTitle: Localized.Common.cancel, style: .cancel) { _ in alert.finish() }
        return alert
    }
}

// MARK: - Library 

extension AlertProcedure {
    class Library {
        static func refreshError(context: UIViewController, message: String) -> AlertProcedure {
            assert(Thread.isMainThread, "Library refresh error alert has to be initialized in the main thread")
            let alert = AlertProcedure(presentAlertFrom: context, withPreferredStyle: .actionSheet, waitForDismissal: true)
            alert.title = Localized.Library.RefreshError.title
            alert.message = message
            alert.add(actionWithTitle: Localized.Common.ok, style: .cancel) { _ in alert.finish() }
            return alert
        }
    }
}

