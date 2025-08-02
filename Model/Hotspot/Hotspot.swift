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
    
    private static let minPort = 1
    nonisolated static let defaultPort = 8080
    private static let maxPort = 65535
    
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
        guard case .valid = await Self.check(port: port) else {
            await MainActor.run {
                state = .error(LocalString.hotspot_settings_already_in_use_port_message(withArgs: "\(port)"))
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
    
    func runningPort() async -> Int? {
        guard let port = await self.hotspot?.__port() else {
            return nil
        }
        return port.intValue
    }
    
    
    /// Check if the given port is in valid range and if occupied by anything else than a running KiwixHotspot
    /// - Parameter port: the port to check
    /// - Returns: the result of the check
    static func check(port: Int) async -> PortCheckResult {
        switch port {
        case minPort...maxPort:
            if let runningPort = await Hotspot.shared.runningPort(),
                runningPort == port {
                // it is used by the currently running Hotspot
                // it must be valid
                return .valid
            }
            if await PortCheck.isOpen(port: port) {
                return .valid
            } else {
                let message = LocalString.hotspot_settings_already_in_use_port_message(withArgs: "\(port)")
                return .invalid(message)
            }
        default:
            let message = LocalString.hotspot_settings_invalid_port_message(withArgs: "\(minPort)", "\(maxPort)")
            return .invalid(message)
        }
    }
}
