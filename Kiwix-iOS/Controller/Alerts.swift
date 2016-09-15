//
//  LibraryAlerts.swift
//  Kiwix
//
//  Created by Chris Li on 9/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class SpaceCautionAlert: UIAlertController {
    convenience init(bookID: String) {
        self.init()
        
        let comment = "Library, Space Alert"
        let title = NSLocalizedString("Space Alert", comment: comment)
        let message = NSLocalizedString("This book will take up more than 80% of your free space after downloaded.", comment: comment)
        self.init(title: title, message: message, preferredStyle: .Alert)
        
        let cancel = UIAlertAction(title: LocalizedStrings.Common.cancel, style: .Cancel, handler: nil)
        let download = UIAlertAction(title: NSLocalizedString("Download Anyway", comment: comment), style: .Destructive, handler: { (_) in
            guard let download = DownloadBookOperation(bookID: bookID) else {return}
            Network.shared.queue.addOperation(download)
        })
        addAction(cancel)
        addAction(download)
        preferredAction = download
    }
}

class SpaceNotEnoughAlert: AlertOperation<UIViewController> {
    init(controller: UIViewController) {
        super.init(presentAlertFrom: controller)
        
        title = LocalizedStrings.Library.spaceNotEnough
        message = NSLocalizedString("Please free up some space and try again.", comment: "Library, Space Alert")
        addActionWithTitle(LocalizedStrings.cancel)
    }
}
