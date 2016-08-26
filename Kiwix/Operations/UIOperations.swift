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

class SpaceNotEnoughAlert: AlertOperation<CloudBooksController> {
    let comment = "Library: Download Space Not Enough Alert"
    init(book: Book, presentationContext: CloudBooksController) {
        super.init(presentAlertFrom: presentationContext)
        
        title = NSLocalizedString("Space Not Enough", comment: comment)
        message = NSLocalizedString("You don't have enough remaining space to download this book.", comment: comment)
        addActionWithTitle(LocalizedStrings.ok)
    }
}

class RefreshLibraryLanguageFilterAlert: AlertOperation<CloudBooksController> {
    let comment = "Library: Language Filter Alert"
    let context = UIApplication.appDelegate.managedObjectContext
    init(presentationContext controller: CloudBooksController) {
        super.init(presentAlertFrom: controller)
        
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
        
        title = NSLocalizedString("Only Show Preferred Language?", comment: comment)
        message = NSLocalizedString("We have found you may know \(languageString), would you like to filter the library by these languages?", comment: comment)
        addActionWithTitle(LocalizedStrings.ok, style: .Default) { (action) in
            self.context.performBlock({
                let languages = Language.fetchAll(self.context)
                for language in languages {
                    guard let code = language.code else {continue}
                    language.isDisplayed = preferredLanguageCodes.contains(code)
                }
                controller.refreshFetchedResultController()
            })
        }
        addActionWithTitle(LocalizedStrings.cancel)
    }
    
    override func operationDidFinish(errors: [ErrorType]) {
        Preference.libraryHasShownPreferredLanguagePrompt = true
    }
    
    private func andJoinedString(a: String, b: String) -> String {
        return a + " " + LocalizedStrings.and + " " + b
    }
}

class RefreshLibraryInternetRequiredAlert: AlertOperation<CloudBooksController> {
    let comment = "Library: Internet Required Alert"
    init(presentationContext: CloudBooksController) {
        super.init(presentAlertFrom: presentationContext)
        
        title = NSLocalizedString("Internet Connection Required", comment: comment)
        message = NSLocalizedString("You need to connect to the Internet to refresh the library.", comment: comment)
        addActionWithTitle(LocalizedStrings.ok)
    }
}

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
            GlobalOperationQueue.sharedInstance.addOperation(operation)
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
