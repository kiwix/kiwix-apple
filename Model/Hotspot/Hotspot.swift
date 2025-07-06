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

@MainActor
final class Hotspot: ObservableObject {
    
    @MainActor
    static let shared = Hotspot()
    
    private static let minPort = 1024
    nonisolated static let defaultPort = 8080
    private static let maxPort = 9999
    
    @ZimActor
    private var hotspot: KiwixHotspot?
    
    @Published private(set) var isStarted: Bool = false
    @Published var selection = MultiSelectedZimFilesViewModel()
    
    @ZimActor
    func toggle() async {
        if let hotspot {
            hotspot.__stop()
            self.hotspot = nil
            await MainActor.run { self.isStarted = false }
            return
        } else {
            let zimFileIds: Set<UUID> = await MainActor.run(
                resultType: Set<UUID>.self,
                body: {
                    Set(selection.selectedZimFiles.map { $0.fileID })
                })
            guard !zimFileIds.isEmpty else {
                debugPrint("no zim files were set for Hotspot to start")
                return
            }
            let portNumber = Int32(Defaults[.hotspotPortNumber])
            self.hotspot = KiwixHotspot(__zimFileIds: zimFileIds, onPort: portNumber)
            await MainActor.run {
                isStarted = true
            }
        }
    }
    
    @MainActor
    func serverAddress() async -> URL? {
        guard let address = await self.hotspot?.__address() else {
            return nil
        }
        return URL(string: address)
    }
    
    static func isValid(port: Int) -> Bool {
        switch port {
        case minPort...maxPort: return true
        default: return false
        }
    }
    
    static var invalidPortMessage: String {
        LocalString.hotspot_settings_invalid_port_message(withArgs: "\(minPort)", "\(maxPort)")
    }
}
