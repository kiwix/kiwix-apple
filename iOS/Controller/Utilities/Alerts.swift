//
//  Alerts.swift
//  Kiwix
//
//  Created by Chris Li on 12/5/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func resourceUnavailable() -> UIAlertController {
        let title = NSLocalizedString("Resource Unavailable", comment: "Resource Unavailable Alert")
        let message = NSLocalizedString(
            "The zim file containing the linked resource may have been deleted or is corrupted.",
            comment: "Resource Unavailable Alert"
        )
        let controller = self.init(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        return controller
    }
    
    static func externalLink(policy: ExternalLinkLoadingPolicy, action: @escaping (()->Void)) -> UIAlertController {
        let title = NSLocalizedString("External Link", comment: "External Link Alert")
        let message: String? = {
            switch policy {
            case .alwaysAsk:
                return NSLocalizedString(
                    "An external link is tapped, do you wish to load the link via Internet?",
                    comment: "External Link Alert"
                )
            case .neverLoad:
                return NSLocalizedString(
                    "An external link is tapped. However, your current setting does not allow it to be loaded.",
                    comment: "External Link Alert"
                )
            default:
                return nil
            }
        }()
        let controller = self.init(title: title, message: message, preferredStyle: .alert)
        if policy == .alwaysAsk {
            controller.addAction(UIAlertAction(
                title: NSLocalizedString("Load the link", comment: "External Link Alert"),
                style: .default,
                handler: { _ in action() }
            ))
            controller.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "External Link Alert"),
                style: .cancel,
                handler: nil
            ))
        } else if policy == .neverLoad {
            controller.addAction(UIAlertAction(
                title: NSLocalizedString("OK", comment: "External Link Alert"),
                style: .cancel,
                handler: nil
            ))
        }
        return controller
    }
}
