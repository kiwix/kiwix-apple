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
import SwiftUI

final class Hotspot {
    
    enum State {
        case started(zimFileIds: Set<UUID>)
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
    private let hotspot = KiwixHotspot()

    @ZimActor
    func startWith(zimFileIds: Set<UUID>) async {
        guard !zimFileIds.isEmpty else {
            debugPrint("no zim files were set for Hotspot to start")
            return
        }
        let port: Int = Defaults[.hotspotPortNumber]
        let portNumber = Int32(port)
        if hotspot.__start(for: zimFileIds, onPort: portNumber) {
            await MainActor.run {
                state = .started(zimFileIds: zimFileIds)
                preventSleep(true)
            }
        } else {
            await MainActor.run {
                state = .error(
                    LocalString.hotspot_error_port_already_used_by_another_app(withArgs: "\(port)")
                )
            }
        }
    }
    
    @ZimActor
    func stop() async {
        hotspot.__stop()
        await MainActor.run {
            state = .stopped
            preventSleep(false)
        }
    }
    
    @MainActor
    func appDidBecomeActive() async {
        if case let .started(zimFileIds) = state {
            Task { @ZimActor in
                await stop()
                await startWith(zimFileIds: zimFileIds)
            }
        }
    }
    
    @MainActor
    private func preventSleep(_ value: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = value
        #endif
    }
    
    func serverAddress() async -> URL? {
        guard let address = await self.hotspot.__address() else {
            return nil
        }
        return URL(string: address)
    }
    
    nonisolated static func validPortRangeMessage() -> String {
        LocalString.hotspot_settings_recommended_port_range(withArgs: "\(minPort)", "\(maxPort)")
    }
    
    nonisolated static var explanationText: String {
        #if os(macOS)
        LocalString.hotspot_server_wifi_only_explanation
        #else
        LocalString.hotspot_server_full_explanation
        #endif
    }
}
