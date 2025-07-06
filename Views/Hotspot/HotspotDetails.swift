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

#if os(macOS)
/// Hotspot multi ZIM files side panel
struct HotspotDetails: View {
    let zimFiles: Set<ZimFile>
    @State private var isPresentingUnlinkAlert: Bool = false
    @State private var serverAddress: URL?
    @ObservedObject private var hotspot = Hotspot.shared
    
    private var buttonTitle: String {
        hotspot.isStarted ? LocalString.hotspot_action_stop_server_title : LocalString.hotspot_action_start_server_title
    }
    
    private func zimFilesCount() -> String {
        Formatter.number.string(from: NSNumber(value: zimFiles.count)) ?? ""
    }
    
    var body: some View {
        List {
            Section(LocalString.multi_zim_files_selected_sidebar_title) {
                Attribute(
                    title: LocalString.multi_zim_files_selected_description_count,
                    detail: zimFilesCount()
                )
            }
            .collapsible(false)
            Section(LocalString.zim_file_list_actions_text) {
                Action(title: buttonTitle) {
                    await hotspot.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
            .collapsible(false)
            
            if let serverAddress {
                Section(LocalString.hotspot_server_running_title) {
                    AttributeLink(title: LocalString.hotspot_server_running_address,
                                  destination: serverAddress)
                    if let qrCode = QRCode.image(from: serverAddress.absoluteString) {
                        qrCode
                            .resizable()
                            .frame(width: 250, height: 250, alignment: .trailing)
                    }
                }
                .collapsible(false)
            }
            Section {
                Text(LocalString.hotspot_server_explanation)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }.collapsible(false)
        }
        .listStyle(.sidebar)
        .onReceive(hotspot.$isStarted) { isStarted in
            if isStarted {
                Task {
                    serverAddress = await hotspot.serverAddress()
                }
            } else {
                serverAddress = nil
            }
        }
    }    
}
#endif
