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

@MainActor
final class NetworkState: ObservableObject {
    @Published
    var isOnline: Bool = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "org.kiwix.network.monitor")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let newValue = path.status == .satisfied
            Task { @MainActor [weak self] in
                if newValue != self?.isOnline {
                    self?.isOnline = newValue
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
