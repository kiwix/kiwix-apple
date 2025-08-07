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

final class Hotspot {
    
    enum PortCheckResult {
        case valid
        case invalid(String)
    }
    
    enum State {
        case started
        case stopped
        case error(String)
    }
    
    @MainActor
    static let shared = Hotspot()
    
    static let minPort = 1
    nonisolated static let defaultPort = 8080
    static let maxPort = 65535
    
    @MainActor
    @Published var state: State = .stopped
    
    @ZimActor
    private var hotspot: KiwixHotspot?

    @ZimActor
    func startWith(zimFileIds: Set<UUID>) async {
        guard hotspot == nil else { return }
        guard !zimFileIds.isEmpty else {
            debugPrint("no zim files were set for Hotspot to start")
            return
        }
        let port: Int = Defaults[.hotspotPortNumber]
        guard PortCheck.isOpen(port: port) else {
            await MainActor.run {
                state = .error(
                    LocalString.hotspot_error_port_already_used_by_another_app(withArgs: "\(port)")
                )
            }
            return
        }
        let portNumber = Int32(port)
        hotspot = KiwixHotspot(__zimFileIds: zimFileIds, onPort: portNumber)
        await MainActor.run {
            state = .started
        }
    }
    
    @ZimActor
    func stop() async {
        guard let hotspot else { return }
        hotspot.__stop()
        self.hotspot = nil
        await MainActor.run { state = .stopped }
    }
    
    func serverAddress() async -> URL? {
        guard let address = await self.hotspot?.__address() else {
            return nil
        }
        return URL(string: address)
    }
    
    nonisolated static func validPortRangeMessage() -> String {
        LocalString.hotspot_settings_recommended_port_range(withArgs: "\(minPort)", "\(maxPort)")
    }
}
