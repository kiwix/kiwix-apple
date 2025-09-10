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
    
    enum State: Equatable {
        case started(zimFileIds: Set<UUID>)
        case stopped
        case error(title: String, description: String)
    }
    
    @MainActor
    static let shared = Hotspot()
    
    static let minPort = 1
    nonisolated static let defaultPort = 80
    static let maxPort = 65535
    
    @MainActor
    @Published var state: State = .stopped
    
    @ZimActor
    private let hotspot = KiwixHotspot()

    @ZimActor
    func startWith(zimFileIds: Set<UUID>, updating: Bool = true) async {
        guard !zimFileIds.isEmpty else {
            debugPrint("no zim files were set for Hotspot to start")
            return
        }
        let port: Int = Defaults[.hotspotPortNumber]
        let portNumber = Int32(port)
        if hotspot.__start(for: zimFileIds, onPort: portNumber) {
            if updating {
                await update(state: .started(zimFileIds: zimFileIds))
            }
            await preventSleep(true)
        } else {
            if updating {
                await update(state: .error(
                    title: LocalString.hotspot_error_port_already_used_by_another_app_title(withArgs: "\(port)"),
                    description: LocalString.hotspot_error_port_already_used_by_another_app_description
                ))
            }
        }
    }
    
    @ZimActor
    func stop(updating: Bool = true) async {
        hotspot.__stop()
        if updating {
            await update(state: .stopped)
        }
        await preventSleep(false)
    }
    
    @MainActor
    func resetError() {
        if case .error = state {
            update(state: .stopped)
            preventSleep(false)
        }
    }
    
    @MainActor
    func appDidBecomeActive() async {
        if case let .started(zimFileIds) = state {
            Task { @ZimActor in
                await stop(updating: false)
                await startWith(zimFileIds: zimFileIds, updating: false)
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
    
    @MainActor
    private func update(state newState: State) {
        if state != newState {
            state = newState
        }
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
