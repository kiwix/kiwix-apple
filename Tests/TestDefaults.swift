// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import Foundation
import Defaults
@testable import Kiwix

final class TestDefaults: NSObject, Defaulting {
    
    var dict: [Defaults._AnyKey: AnyObject] = [:]
    
    func setup() {
        self[.categoriesToLanguages] = [:]
        self[.libraryAutoRefresh] = false
        self[.libraryETag] = ""
        self[.libraryUsingOldISOLangCodes] = false
        self[.libraryLanguageCodes] = Set<String>()
    }
    
    subscript<Value>(key: Defaults.Key<Value>) -> Value {
        get {
            // swiftlint:disable:next force_cast
            dict[key] as! Value
        }
        set {
            dict[key] = newValue as AnyObject
        }
    }
}
