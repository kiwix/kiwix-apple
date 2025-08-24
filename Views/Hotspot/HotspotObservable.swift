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

import SwiftUI
import Combine

enum HotspotState: Equatable {
    @MainActor static let selection = MultiSelectedZimFilesViewModel()
    
    case started(URL, CGImage?)
    case stopped
    case error(title: String, description: String)
    
    var isStarted: Bool {
        switch self {
        case .stopped: return false
        case .error: return false
        case .started: return true
        }
    }
}

@MainActor
final class HotspotObservable: ObservableObject {
    
    @Published var buttonTitle: String = LocalString.hotspot_action_start_hotspot_title
    @Published var state: HotspotState = .stopped
    private var hotspot = Hotspot.shared
    private var cancellables = Set<AnyCancellable>()
    @MainActor
    static let shared = HotspotObservable()
    
    private init() {
        hotspot.$state.sink { [weak self] state in
            Task { [weak self] in
                await self?.update(hotspotState: state)
            }
        }.store(in: &cancellables)
    }
    
    func toggleWith(zimFileIds: Set<UUID>) async {
        if state.isStarted {
            await hotspot.stop()
        } else {
            await hotspot.startWith(zimFileIds: zimFileIds)
        }
    }
    
    func resetError() {
        hotspot.resetError()
    }
    
    private func update(hotspotState: Hotspot.State) async {
        switch hotspotState {
        case .started:
            buttonTitle = LocalString.hotspot_action_stop_hotspot_title
            let address = await hotspot.serverAddress()
            if let address {
                update(state: .started(address, nil))
                let qrCodeImage = await QRCode.image(from: address.absoluteString)
                update(state: .started(address, qrCodeImage))
            } else {
                update(state: .stopped)
            }
        case .stopped:
            buttonTitle = LocalString.hotspot_action_start_hotspot_title
            update(state: .stopped)
        case let .error(title, description):
            buttonTitle = LocalString.hotspot_action_start_hotspot_title
            update(state: .error(title: title, description: description))
        }
    }
    
    private func update(state newState: HotspotState) {
        if state != newState {
            state = newState
        }
    }
}
