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
    let zimFileIds: Set<UUID>
    @ObservedObject var hotspot: HotspotObservable
    
    private func zimFilesCount() -> String {
        Formatter.number.string(from: NSNumber(value: zimFileIds.count)) ?? ""
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
                Action(title: hotspot.buttonTitle) {
                    await hotspot.toggleWith(zimFileIds: zimFileIds)
                }
                .buttonStyle(.borderedProminent)
            }
            .collapsible(false)
            
            if case .started(let address, let qrCodeImage) = hotspot.state {
                HotspotAddress(serverAddress: address, qrCodeImage: qrCodeImage)
            }
            if let errorMessage = hotspot.errorMessage {
                Section {
                    Text(errorMessage)
                        .fontWeight(.bold)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.red)
                }
            }
            HotspotExplanation()
        }
        .listStyle(.sidebar)
    }    
}
#endif
