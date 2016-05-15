//
//  UtilitiesString.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

extension Utilities {
    
    class func formattedDateStringFromDate(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .MediumStyle
        return formatter.stringFromDate(date)
    }
    
    class func formattedFileSizeStringFromByteCount(fileBytes: Int64?) -> String {
        guard let fileBytes = fileBytes else {return LocalizedStrings.unknown}
        return NSByteCountFormatter.stringFromByteCount(fileBytes, countStyle: .File)
    }
    
    class func formattedPercentString(number: NSNumber) -> String? {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.maximumIntegerDigits = 3
        formatter.maximumFractionDigits = 0
        formatter.locale = NSLocale.currentLocale()
        return formatter.stringFromNumber(number)
    }
    
    class func formattedNumberStringFromDouble(num: Double) -> String {
        let sign = ((num < 0) ? "-" : "" )
        let abs = fabs(num)
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
