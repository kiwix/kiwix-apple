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

/// A grid of zim files that are opened, or was open but is now missing.
/// A specific version of ZimFilesOpened, supporting multi selection for HotSpot
struct HotspotZimFilesSelection: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate,
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @StateObject private var selection: MultiSelectedZimFilesViewModel
    @ObservedObject private var hotspot = HotspotObservable()
    
    init(
        selectionProvider: @MainActor () -> MultiSelectedZimFilesViewModel = { @MainActor in HotspotState.selection }
    ) {
        let selectionInstance = selectionProvider()
        _selection = StateObject(wrappedValue: selectionInstance)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if zimFiles.isEmpty {
                Message(text: LocalString.zim_file_opened_overlay_no_opened_message)
            } else {
                LazyVGrid(
                    columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
                    alignment: .leading,
                    spacing: 12
                ) {
                    if case .started(let address, let qrCodeImage) = hotspot.state {
                        
                        HotspotCell {
                            HStack {
                                Spacer()
                                Group {
                                    if let qrCodeImage {
                                        qrCodeImage.resizable()
                                    } else {
                                        ProgressView().progressViewStyle(.circular)
                                    }
                                }
                                .frame(idealWidth: 240, maxWidth: 300, idealHeight: 240, maxHeight: 300)
                                .aspectRatio(1.0, contentMode: .fill)
                                Spacer()
                            }
                        }
                        
                        VStack {
                            HotspotCell {
                                VStack(alignment: .leading, spacing: 8) {
                                    Link(address.absoluteString, destination: address)
                                        .fontWeight(.semibold).foregroundColor(.accentColor).lineLimit(1)
                                    Spacer()
                                    HStack(alignment: .bottom, spacing: 12) {
                                        Spacer()
                                        ShareLink(item: address) {
                                            Label(LocalString.common_button_share, systemImage: "square.and.arrow.up")
                                        }
                                        CopyPasteMenu(url: address)
                                    }
#if os(macOS)
                                    .buttonStyle(.borderless)
                                    .foregroundStyle(Color.accentColor)
#endif
                                }
                            }
                            .frame(maxHeight: 91)
                            
                            HotspotCell {
                                HotspotExplanation()
                            }
                        }
                        
                    } else {
                        ForEach(zimFiles) { zimFile in
                            MultiZimFilesSelectionContext(
                                content: {
                                    ZimFileCell(
                                        zimFile,
                                        prominent: .name,
                                        isSelected: selection.isSelected(zimFile),
                                        backgroundColoring: CellBackground.hotspotSelectionColorFor
                                    )
                                },
                                zimFile: zimFile,
                                selection: selection
                            )
                        }
                    }
                }
            }
        }
        .modifier(GridCommon(edges: .all))
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(MenuItem.hotspot.name)
        .task {
            // make sure that our selection only contains still existing ZIM files
            selection.intersection(with: Set(zimFiles))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                AsyncButton {
                    await hotspot.toggleWith(
                        zimFileIds: Set(selection.selectedZimFiles.map { $0.fileID })
                    )
                } label: {
                    Text(hotspot.buttonTitle)
                        .bold()
                }
#if os(macOS)
                .buttonStyle(.borderless)
#endif
                .disabled(selection.selectedZimFiles.isEmpty && !hotspot.state.isStarted)
                .modifier(BadgeModifier(count: selection.selectedZimFiles.count))
            }
        }
    }
}
