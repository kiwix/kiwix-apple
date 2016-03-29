//
//  AlertOperations.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SpaceCautionAlert: AlertOperation {
    init(book: Book, presentationContext: UIViewController?) {
        super.init(presentationContext: presentationContext)
        
        let comment = "Library: Download Space Caution Alert"
        
        title = NSLocalizedString("Space Caution", comment: comment)
        message = NSLocalizedString("This book takes up more than 80% of the remaining space on your device. Are you sure you want to download it?", comment: comment)
        addAction(NSLocalizedString("Download Anyway", comment: comment), style: .Default) { (action) -> Void in
            Network.sharedInstance.download(book)
        }
        addAction(LocalizedStrings.cancel)
    }
}

class SpaceNotEnoughAlert: AlertOperation {
    init(book: Book, presentationContext: UIViewController?) {
        super.init(presentationContext: presentationContext)
        
        let comment = "Library: Download Space Not Enough Alert"
        
        title = NSLocalizedString("Space Not Enough", comment: comment)
        message = NSLocalizedString("You don't have enough remaining space to download this book.", comment: comment)
        addAction(LocalizedStrings.ok)
    }
}