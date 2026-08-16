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

@MainActor
final class Debouncer {
    private var task: Task<Void, Never>?
    
    func debounce(milliseconds: UInt64, action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        let nanoseconds = milliseconds * 1_000_000
        task = Task(priority: .utility, operation: {
            try? await Task.sleep(nanoseconds: nanoseconds)
            if !Task.isCancelled {
                await action()
            }
        })
    }
}
