//
//  StringTools.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Foundation

extension String {
    static func formattedDateString(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .MediumStyle
        return formatter.stringFromDate(date)
    }
    
    static func formattedFileSizeString(fileBytes: Int64?) -> String {
        guard let fileBytes = fileBytes else {return LocalizedStrings.unknown}
        return NSByteCountFormatter.stringFromByteCount(fileBytes, countStyle: .File)
    }
    
    static func formattedPercentString(double: Double) -> String? {
        let number = NSNumber(double: double)
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.maximumIntegerDigits = 3
        formatter.maximumFractionDigits = 0
        formatter.locale = NSLocale.currentLocale()
        return formatter.stringFromNumber(number)
    }
    
    static func formattedNumberString(double: Double) -> String {
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

