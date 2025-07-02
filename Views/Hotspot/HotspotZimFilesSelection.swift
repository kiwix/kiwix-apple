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
import UniformTypeIdentifiers

/// A grid of zim files that are opened, or was open but is now missing.
/// A specific version of ZimFilesOpened, supporting multi selection for HotSpot
struct HotspotZimFilesSelection: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isFileImporterPresented = false
    @StateObject private var selection = MultiSelectedZimFilesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            LazyVGrid(
                columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(zimFiles) { zimFile in
                    MultiZimFilesSelectionContext(
                        content: {
                            ZimFileCell(
                                zimFile,
                                prominent: .name,
                                isSelected: selection.isSelected(zimFile)
                            )
                        },
                        zimFile: zimFile,
                        selection: selection)
                }
            }
            .modifier(GridCommon(edges: .all))
            .modifier(ToolbarRoleBrowser())
            .navigationTitle(MenuItem.hotspot.name)
            .overlay {
                if zimFiles.isEmpty {
                    Message(text: LocalString.zim_file_opened_overlay_no_opened_message)
                }
            }
            .onChange(of: zimFiles.count) { _ in
                if let firstZimFile = zimFiles.first {
                    selection.singleSelect(zimFile: firstZimFile)
                } else {
                    selection.reset()
                }
            }
            .safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    //TODO: handle started / stopped state of hotspot here as well
                    switch selection.selectedZimFiles.count {
                    case 0:
                        Message(text: LocalString.hotspot_zim_file_selection_message)
                            .background(.thickMaterial)
                    default:
                        HotspotDetails(zimFiles: selection.selectedZimFiles)
                    }
                }.frame(width: 275).background(.ultraThinMaterial)
            }
        }
    }
}
