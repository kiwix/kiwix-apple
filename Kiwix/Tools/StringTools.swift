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
    class Alert {
        static let ok = NSLocalizedString("OK", comment: "Alert action")
        static let cancel = NSLocalizedString("Cancel", comment: "Alert action")
    }
    
}
