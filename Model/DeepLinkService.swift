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

/// Helper to figure out if a deeplink started ZIM file
/// handling is already running.
/// In that case we do not want to handle the default
/// navigation to the latest opened ZIM file
@MainActor
final class DeepLinkService {
    
    static let shared = DeepLinkService()
    
    private var ids = Set<UUID>()
    
    private init() {}
    
    func startFor(uuid: UUID) {
        ids.insert(uuid)
    }
    
    func stopFor(uuid: UUID) {
        ids.remove(uuid)
    }
    
    func isRunning() -> Bool {
        !ids.isEmpty
    }
}
