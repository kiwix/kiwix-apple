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

@MainActor
final class Hotspot: ObservableObject {
    
    @MainActor
    static let shared = Hotspot()
    
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
            let zimFileIds: Set<UUID> = await MainActor.run(resultType: Set<UUID>.self, body: {
                Set(selection.selectedZimFiles.map{ $0.fileID })
            })
            guard !zimFileIds.isEmpty else {
                debugPrint("no zim files were set for Hotspot to start")
                return
            }
            self.hotspot = KiwixHotspot(__zimFileIds: zimFileIds)
            await MainActor.run {
                isStarted = true
                debugPrint("current IP: \(Self.wifiIPaddress())")
            }
        }
    }
    
    static func wifiIPaddress() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    let wifi = "en0"
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
                    
                    let name: String = String(cString: (interface.ifa_name))
                    if  name == wifi {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
}
