//
//  Formatter.swift
//  Kiwix
//
//  Created by Chris Li on 6/28/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import Foundation

enum Formatter {
    static let dateShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let dateMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let size: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    static let number: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    
    static func largeNumber(_ value: Int64) -> String {
        let sign = ((value < 0) ? "-" : "" )
        let abs = Swift.abs(value)
        guard abs >= 1000 else {return "\(sign)\(abs)"}
        let exp = Int(log10(Double(abs)) / log10(1000))
        let units = ["K", "M", "G", "T", "P", "E"]
        let rounded = round(10 * Double(abs) / pow(1000.0, Double(exp))) / 10
        return "\(sign)\(rounded)\(units[exp-1])"
    }
}
