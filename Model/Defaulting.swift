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

protocol Defaulting: NSObjectProtocol {
    subscript<Value: Defaults.Serializable>(key: Defaults.Key<Value>) -> Value { get set }
}

final class UDefaults: NSObject, Defaulting {
    subscript<Value>(key: Defaults.Key<Value>) -> Value where Value : DefaultsSerializable {
        get {
            Defaults[key]
        }
        set {
            Defaults[key] = newValue
        }
    }
}

/*
 static subscript<Value: Serializable>(key: Key<Value>) -> Value {
     get { key.suite[key] }
     set {
         key.suite[key] = newValue
     }
 }
 */
