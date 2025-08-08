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

enum HotspotState {
    @MainActor static let selection = MultiSelectedZimFilesViewModel()
    
    case started(URL, CGImage?)
    case stopped
    case error(String)
    
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
    
    init() {
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
    
    private func update(hotspotState: Hotspot.State) async {
        switch hotspotState {
        case .started:
            buttonTitle = LocalString.hotspot_action_stop_hotspot_title
            let address = await hotspot.serverAddress()
            if let address {
                state = .started(address, nil)
                let qrCodeImage = await QRCode.image(from: address.absoluteString)
                state = .started(address, qrCodeImage)
            } else {
                state = .stopped
            }
        case .stopped:
            buttonTitle = LocalString.hotspot_action_start_hotspot_title
            state = .stopped
        case let .error(message):
            buttonTitle = LocalString.hotspot_action_start_hotspot_title
            state = .error(message)
        }
    }
}
