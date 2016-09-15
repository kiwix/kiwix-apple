//
//  LibraryAlerts.swift
//  Kiwix
//
//  Created by Chris Li on 9/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class SpaceNotEnoughAlert: AlertOperation<UIViewController> {
    init(context: UIViewController) {
        super.init(presentAlertFrom: context)
        title = LocalizedStrings.Library.spaceNotEnough
        message = NSLocalizedString("Please free up some space and try again.", comment: "Library, Space Alert")
        addActionWithTitle(LocalizedStrings.cancel)
    }
}

class SpaceCautionAlert: AlertOperation<UIViewController> {
    init(context: UIViewController, bookID: String) {
        super.init(presentAlertFrom: context)
        
        title = NSLocalizedString("Space Alert", comment: "Library, Space Alert")
        message = NSLocalizedString("This book will take up more than 80% of your free space after downloaded.", comment: "Library, Space Alert")
        addActionWithTitle(NSLocalizedString("Download Anyway", comment: "Library, Space Alert"), style: .Destructive) { _ in
            guard let download = DownloadBookOperation(bookID: bookID) else {return}
            Network.shared.queue.addOperation(download)
        }
        addActionWithTitle(LocalizedStrings.cancel)
        preferredAction = actions[0]
    }
}

class RemoveBookConfirmationAlert: AlertOperation<UIViewController> {
    init(context: UIViewController, bookID: String) {
        super.init(presentAlertFrom: context)
        
        title = NSLocalizedString("Remove this book?", comment: "Library, Delete Alert")
        message = NSLocalizedString("This operation is not recoverable. All bookmarks in this book will also be removed!", comment: "Library, Delete Alert")
        addActionWithTitle(LocalizedStrings.remove, style: .Destructive) { _ in
            let operation = RemoveBookOperation(bookID: bookID)
            GlobalQueue.shared.addOperation(operation)
        }
        addActionWithTitle(LocalizedStrings.ok)
        preferredAction = actions[0]
    }
}

class NetworkRequiredAlert: AlertOperation<UIViewController> {
    init(context: UIViewController) {
        super.init(presentAlertFrom: context)
        title = NSLocalizedString("Network Required", comment: "Network Required Alert")
        message = NSLocalizedString("Unable to connect to server. Please check your Internet connection.", comment: "Network Required Alert")
        addActionWithTitle(LocalizedStrings.cancel)
    }
}
