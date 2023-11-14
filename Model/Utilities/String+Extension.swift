//
//  String+Extension.swift
//  Kiwix
//
//  Created by tvision251 on 11/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import Foundation

extension String {
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func localized(withComment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
    
    func localizedWithFormat(withArgs: CVarArg...) -> String {
        let format = NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        
        switch withArgs.count {
            case 1: return String.localizedStringWithFormat(format, withArgs[0])
            case 2: return String.localizedStringWithFormat(format, withArgs[0], withArgs[1])
            default: return String.localizedStringWithFormat(format, withArgs)
        }
    }
    
}

