//
//  UIOperations.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

// MARK: - Alerts


class GetStartedAlert: AlertOperation<MainController> {
    let comment = "First Time Launch Message"
    init(presentationContext mainController: MainController) {
        super.init(presentAlertFrom: mainController)
        
        title = NSLocalizedString("Welcome to Kiwix", comment: comment)
        message = NSLocalizedString("Add a Book to Get Started", comment: comment)
        addActionWithTitle(NSLocalizedString("Download", comment: comment), style: .Default) { (alert) in
            mainController.showLibraryButtonTapped()
        }
        addActionWithTitle(NSLocalizedString("Import", comment: comment), style: .Default) { (alert) in
            let operation = ShowHelpPageOperation(type: .ImportBookLearnMore, presentationContext: mainController)
            GlobalQueue.shared.addOperation(operation)
        }
        addActionWithTitle(NSLocalizedString("Dismiss", comment: comment))
    }
}

// MARK: - Help Pages

class ShowHelpPageOperation: Operation {
    private let type: WebViewControllerContentType
    private let presentationContext: UIViewController
    
    init(type: WebViewControllerContentType, presentationContext: UIViewController) {
        self.type = type
        self.presentationContext = presentationContext
        super.init()
    }
    
    override func execute() {
        defer { finish() }
        guard let controller = UIStoryboard.setting.instantiateViewControllerWithIdentifier("WebViewController") as? WebViewController else {return}
        controller.page = self.type
        
        let operation = UIOperation(controller: UIViewController(),
                                    displayControllerFrom: .Present(presentationContext),
                                    inNavigationController: true,
                                    sender: nil)
        produceOperation(operation)
    }
}
