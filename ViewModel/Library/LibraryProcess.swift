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

enum LibraryState {
    case initial
    case inProgress
    case complete
    case error

    static func defaultState(defaults: Defaulting = UDefaults()) -> LibraryState {
        if defaults[.libraryLastRefresh] == nil {
            return .initial
        } else {
            return .complete
        }
    }
}

/// Makes sure that the process value is stored in a single state
/// regardless of the amount of instances we have for LibraryViewModel
@MainActor final class LibraryProcess: ObservableObject {
    static let shared = LibraryProcess()
    @Published var state: LibraryState

    init(defaultState: LibraryState = .defaultState()) {
        state = defaultState
    }
}
