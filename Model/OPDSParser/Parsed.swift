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

/// Sendable data that is comming out of the OPDSParser
struct Parsed {
    let results: [UUID: ZimFileMetaStruct]
    
    /// An empty result we can use to delete zim entries
    /// Based on the assumption we insert new ones, delete the ones not on the list
    /// Therefore an empty list will delete everything, using the same method
    /// @see: LibraryViewModel.process(parsed: Parsed)
    static func deletingResult() -> Parsed {
        Parsed(results: [:])
    }
}
