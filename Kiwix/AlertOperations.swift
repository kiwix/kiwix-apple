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

class LanguageFilterAlert: AlertOperation {
    init(libraryOnlineTBVC: LibraryOnlineTBVC) {
        super.init(presentationContext: libraryOnlineTBVC)
        
        var preferredLanguageCodes = [String]()
        var preferredLanguageNames = [String]()
        
        for code in NSLocale.preferredLanguages() {
            guard let code = code.componentsSeparatedByString("-").first else {continue}
            guard let name = NSLocale.currentLocale().displayNameForKey(NSLocaleIdentifier, value: code) else {continue}
            preferredLanguageCodes.append(code)
            preferredLanguageNames.append(name)
        }
        print(preferredLanguageCodes)
        
        let languageString: String = {
            switch preferredLanguageNames.count {
            case 0:
                return ""
            case 1:
                return preferredLanguageNames[0]
            case 2:
                return andJoinedString(preferredLanguageNames[0], b: preferredLanguageNames[1])
            default:
                let last = preferredLanguageNames.popLast()!
                let secondToLast = preferredLanguageNames.popLast()!
                return preferredLanguageNames.joinWithSeparator(", ") + ", " + andJoinedString(secondToLast, b: last)
            }
        }()
        
        let comment = "Library: Language Filter Alert"
        
        title = NSLocalizedString("Only Show Preferred Language?", comment: comment)
        message = NSLocalizedString("We have found you may know \(languageString), would you like to filter the library by these languages?", comment: comment)
        addAction(LocalizedStrings.ok, style: .Default) { (action) in
            let languages = Language.fetchAll(UIApplication.appDelegate.managedObjectContext)
            for language in languages {
                guard let code = language.code else {continue}
                language.isDisplayed = preferredLanguageCodes.contains(code)
            }
            libraryOnlineTBVC.refreshFetchedResultController()
        }
        addAction(LocalizedStrings.cancel)
    }
    
    override func finished(errors: [NSError]) {
        Preference.libraryHasShownPreferredLanguagePrompt = true
    }
    
    func andJoinedString(a: String, b: String) -> String {
        return a + " " + LocalizedStrings.and + " " + b
    }
}