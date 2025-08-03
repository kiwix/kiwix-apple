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
    @StateObject private var selection: MultiSelectedZimFilesViewModel
    @ObservedObject private var hotspot = HotspotObservable()
    @State private var presentedSheet: PresentedSheet?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var hotspotError: String?
    
    private enum PresentedSheet: Identifiable {
        case shareHotspot(url: URL)
        
        var id: String {
            switch self {
            case .shareHotspot: return "shareHotspot"
            }
        }
    }
    
    init(
        selectionProvider: @MainActor () -> MultiSelectedZimFilesViewModel = { @MainActor in HotspotState.selection }
    ) {
        let selectionInstance = selectionProvider()
        _selection = StateObject(wrappedValue: selectionInstance)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let hotspotError {
                Text(hotspotError)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
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
                                isSelected: selection.isSelected(zimFile),
                                backgroundColoring: CellBackground.hotspotSelectionColorFor
                            )
                        },
                        zimFile: zimFile,
                        selection: selection
                    )
                }
            }
            .disabled(hotspot.state.isStarted)
            .modifier(GridCommon(edges: .all))
            .modifier(ToolbarRoleBrowser())
            .navigationTitle(MenuItem.hotspot.name)
            .task {
                // make sure that our selection only contains still existing ZIM files
                selection.intersection(with: Set(zimFiles))
            }
#if os(iOS)
            .onReceive(hotspot.$state) { state in
                switch state {
                case let .error(errorMessage):
                    hotspotError = errorMessage
                case .started, .stopped:
                    hotspotError = nil
                }
            }
            .overlay {
                if zimFiles.isEmpty {
                    Message(text: LocalString.zim_file_opened_overlay_no_opened_message)
                }
                if case .started(let address, let qrCodeImage) = hotspot.state {
                    List {
                        HotspotAddress(serverAddress: address, qrCodeImage: qrCodeImage, onShare: {
                            if horizontalSizeClass == .compact {
                                // for (compact) iPhone we want to close the whole library popup
                                // and display the share dialog instead of it
                                // going all the way back to CompactView(Controller)
                                NotificationCenter.hotspotShare(url: address)
                            } else {
                                // for (regular) iPad we can display the share dialog right here
                                presentedSheet = .shareHotspot(url: address)
                            }
                        })
                        HotspotExplanation()
                    }
                }
            }
            .sheet(item: $presentedSheet) { presentedSheet in
                switch presentedSheet {
                case .shareHotspot(let url):
                    ActivityViewController(activityItems: [url].compactMap { $0 })
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AsyncButton {
                        await hotspot.toggleWith(
                            zimFileIds: Set(selection.selectedZimFiles.map { $0.fileID })
                        )
                    } label: {
                        Text(hotspot.buttonTitle)
                            .bold()
                    }
                    .disabled(selection.selectedZimFiles.isEmpty && !hotspot.state.isStarted)
                    .modifier(BadgeModifier(count: selection.selectedZimFiles.count))
                }
            }
#endif
#if os(macOS)
            .overlay {
                if zimFiles.isEmpty {
                    Message(text: LocalString.zim_file_opened_overlay_no_opened_message)
                }
            }
            .safeAreaInset(edge: .trailing, spacing: 0) {
                HStack(spacing: 0) {
                    Divider()
                    switch selection.selectedZimFiles.count {
                    case 0:
                        Message(text: LocalString.hotspot_zim_file_selection_message)
                            .background(.thickMaterial)
                    default:
                        HotspotDetails(zimFileIds: Set(selection.selectedZimFiles.map { $0.fileID }),
                                       hotspot: hotspot)
                    }
                }
                .frame(width: 275)
                .background(.ultraThinMaterial)
            }
#endif
        }
    }
}
