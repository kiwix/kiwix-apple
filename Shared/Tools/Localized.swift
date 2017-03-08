//
//  StringTools.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation

class LocalizedStrings {
    static let bookmarks = NSLocalizedString("Bookmarks", comment: "Common")
    static let search = NSLocalizedString("Search", comment: "Common")
    
    static let cloud = NSLocalizedString("Cloud", comment: "Common")
    static let download = NSLocalizedString("Download", comment: "Common")
    static let local = NSLocalizedString("Local", comment: "Common")
    
    static let spaceNotEnough = NSLocalizedString("Space Not Enough", comment: "Common")
    static let pause = NSLocalizedString("Pause", comment: "Common")
    static let resume = NSLocalizedString("Resume", comment: "Common")
    static let restart = NSLocalizedString("Restart", comment: "Common")
    static let cancel = NSLocalizedString("Cancel", comment: "Common")
    static let remove = NSLocalizedString("Remove", comment: "Common")
    
    static let yes = NSLocalizedString("Yes", comment: "Common")
    static let on = NSLocalizedString("On", comment: "Common")
    static let off = NSLocalizedString("Off", comment: "Common")
    static let and = NSLocalizedString("and", comment: "Common")
    static let done = NSLocalizedString("Done", comment: "Common")
}

class Localized {
    
    // MARK: - Common
    
    class Common {
        static let ok = NSLocalizedString("OK", comment: "Alert action")
        static let cancel = NSLocalizedString("Cancel", comment: "Alert action")
    }
    
    // MARK: - Library
    
    class Library {
        static let cloudTitle = NSLocalizedString("Cloud", comment: "Library, Cloud")
        static let localTitle = NSLocalizedString("Local", comment: "Library, Local")
        
        static let download = NSLocalizedString("Download", comment: "Library, more action sheet")
        static let copyURL = NSLocalizedString("Copy URL", comment: "Library, more action sheet")
        
        class LanguageFilter {
            static let title = NSLocalizedString("Languages", comment: "Library, Language Filter")
            static let all = NSLocalizedString("ALL", comment: "Library, Language Filter")
            static let showing = NSLocalizedString("SHOWING", comment: "Library, Language Filter")
            static let hiding = NSLocalizedString("HIDING", comment: "Library, Language Filter")
            static let original = NSLocalizedString("Original", comment: "Library, Language Filter")
        }
        
        class LanguageFilterAlert {
            static let title = NSLocalizedString("Filter Languages?", comment: "Library, Language Filter Alert")
            static let message = NSLocalizedString("Would you like to hide books", comment: "Library, Language Filter Alert")
        }
        
        class RefreshError {
            static let title = NSLocalizedString("Unable to refresh library", comment: "Library, Refresh Error")
            static let subtitle = NSLocalizedString("Please try again later", comment: "Library, Refresh Error")
        }
    }
    
    // MARK: - Setting
    
    class Setting {
        static let title = NSLocalizedString("Setting", comment: "Setting table title")
        
        static let fontSize = NSLocalizedString("Font Size", comment: "Setting table rows")
        static let notifications = NSLocalizedString("Notifications", comment: "Setting table rows")
        static let history = NSLocalizedString("History", comment: "History Setting")
        static let feedback = NSLocalizedString("Email us your suggestions", comment: "Setting table rows")
        static let rateApp = NSLocalizedString("Give Kiwix a Rate", comment: "Setting table rows")
        static let about = NSLocalizedString("About", comment: "Setting table rows")
        static let version = NSLocalizedString("Kiwix for iOS v%@", comment: "Setting table footer")
        
        class Notifications {
            static let libraryRefresh = NSLocalizedString("Background Library Refresh", comment: "Notification Setting")
            static let bookUpdateAvailable = NSLocalizedString("Book Update Available", comment: "Notification Setting")
            static let bookDownloadFinish = NSLocalizedString("Book Download Finish", comment: "Notification Setting")
        }
        
        class History {
            class Search {
                static let title = NSLocalizedString("Clear Search History", comment: "History Setting")
                static let cleared = NSLocalizedString("Search History Cleared", comment: "History Setting")
            }
            
            class Browsing {
                static let title = NSLocalizedString("Clear Browsing History", comment: "History Setting")
                static let cleared = NSLocalizedString("Browsing History Cleared", comment: "History Setting")
            }
        }
        
        class Feedback {
            static let subject = NSLocalizedString(String(format: "Feedback: Kiwix for iOS %@", Bundle.appShortVersion),
                                                   comment: "Feedback email composer subject, %@ will be replaced by kiwix version string")
            class Success {
                static let title = NSLocalizedString("Email Sent", comment: "Feedback success title")
                static let message = NSLocalizedString("Your Email was sent successfully.", comment: "Feedback success message")
            }
            class NotConfiguredError {
                static let title = NSLocalizedString("Cannot send Email", comment: "Feedback error title")
                static let message = NSLocalizedString("The device is not configured to send email. You can send an email to chris@kiwix.org using other devices.", comment: "Feedback error message")
            }
            class ComposerError {
                static let title = NSLocalizedString("Email not sent", comment: "Feedback error title")
            }
        }
        
        class RateApp {
            static let message = NSLocalizedString("Would you like to rate Kiwix in App Store?", comment: "Rate app alert message")
            static let goToAppStore = NSLocalizedString("Go to App Store", comment: "Rate app alert action")
            static let remindMeLater = NSLocalizedString("Remind Me Later", comment: "Rate app alert action")
        }
    }
    
}
