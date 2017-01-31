//
//  StringTools.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import Foundation

extension String {
    static func formattedDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    static func formattedFileSizeString(_ fileBytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: fileBytes, countStyle: .file)
    }
    
    static func formattedPercentString(_ double: Double) -> String? {
        let number = NSNumber(value: double as Double)
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumIntegerDigits = 3
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale.current
        return formatter.string(from: number)
    }
    
    static func formattedNumberString(_ double: Double) -> String {
        let sign = ((double < 0) ? "-" : "" )
        let abs = fabs(double)
        guard abs >= 1000.0 else {
            if abs - Double(Int(abs)) == 0 {
                return "\(sign)\(Int(abs))"
            } else {
                return "\(sign)\(abs)"
            }
        }
        let exp: Int = Int(log10(abs) / log10(1000))
        let units: [String] = ["K","M","G","T","P","E"]
        let roundedNum: Double = round(10 * abs / pow(1000.0,Double(exp))) / 10;
        return "\(sign)\(roundedNum)\(units[exp-1])"
    }
}

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
    }
    
    // MARK: - Setting
    
    class Setting {
        static let title = NSLocalizedString("Setting", comment: "Setting table title")
        
        static let fontSize = NSLocalizedString("Font Size", comment: "Setting table rows")
        static let notifications = NSLocalizedString("Notifications", comment: "Setting table rows")
        static let feedback = NSLocalizedString("Email us your suggestions", comment: "Setting table rows")
        static let rateApp = NSLocalizedString("Give Kiwix a Rate", comment: "Setting table rows")
        static let about = NSLocalizedString("About", comment: "Setting table rows")
        static let version = NSLocalizedString("Kiwix for iOS v%@", comment: "Setting table footer")
        
        class Notifications {
            static let libraryRefresh = NSLocalizedString("Library Refresh", comment: "Notification Setting")
            static let bookUpdateAvailable = NSLocalizedString("Book Update Available", comment: "Notification Setting")
            static let bookDownloadFinish = NSLocalizedString("Book Download Finish", comment: "Notification Setting")
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
