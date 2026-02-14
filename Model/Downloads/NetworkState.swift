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
import Network

// Mapped state from `OnlineState` plus
// from the session download task
// depending if it allows cellular access or not
// it is PER DOWNLOAD task
enum DownloadTaskNetworkState {
    init(onlineState: OnlineState, downloadAllowsCellular: Bool) {
        switch (onlineState, downloadAllowsCellular) {
        case (.offline, _):
            self = .offline
        case (.onlineOnCellularOnly, false):
            self = .waitingForWifi
        default:
            self = .online
        }
    }
    
    case offline
    case waitingForWifi
    case online
}

/// States that are comming from the GLOBAL network state listener
enum OnlineState {
    init(hasConnection: Bool, hasOnlyCellular: Bool) {
        switch (hasConnection, hasOnlyCellular) {
        case (false, _):
            self = .offline
        case (true, false):
            self = .online
        case (true, true):
            self = .onlineOnCellularOnly
        }
    }
    
    case offline
    case onlineOnCellularOnly
    case online
}

final class NetworkState: ObservableObject {
    @MainActor
    @Published
    var onlineState: OnlineState = .online
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "org.kiwix.network.monitor")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let hasConnection = path.status == .satisfied
            // if there is any other type of connection (eg: wired lan)
            // it means we are not only on cellular
            let types: [NWInterface.InterfaceType] = path.availableInterfaces.map { $0.type }
            let hasOnlyCellular = types.filter { $0 != .cellular }.isEmpty
            let newState = OnlineState(hasConnection: hasConnection, hasOnlyCellular: hasOnlyCellular)
            Task { @MainActor [weak self] in
                if newState != self?.onlineState {
                    self?.onlineState = newState
                }
            }
        }
    }
    
    func startMonitoring() {
        guard monitor.queue == nil else { return }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        guard monitor.queue != nil else { return }
        monitor.cancel()
    }
}
