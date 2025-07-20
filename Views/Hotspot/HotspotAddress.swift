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

struct HotspotAddress: View {
    let serverAddress: URL
    let qrCodeImage: Image?
    #if os(macOS)
    @StateObject private var windowTracker = WindowTracker()
    #else
    let onShare: () -> Void
    #endif
    var body: some View {
        //        Section(LocalString.hotspot_server_running_title) {
        VStack {
//            Text(LocalString.hotspot_server_running_title)
//                .font(.title)
            
            AttributeLinkWithShare(
                title: LocalString.hotspot_server_running_address,
                destination: serverAddress,
                onShare: onShare
            )
            #if os(macOS)
            if let contentView = windowTracker.current?.contentView {
                HStack {
                    Spacer()
                    ShareButton(
                        url: serverAddress,
                        relativeToView: contentView,
                        origin: CGPoint(x: 640, y: 220),
                        preferredEdge: .maxX
                    )
                }
            }
            #endif
            Spacer()
            if let qrCodeImage {
                qrCodeImage
                    .resizable()
                    .frame(width: 250, height: 250)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 250, height: 250)
            }
            Spacer()
        }
#if os(macOS)
        .collapsible(false)
        .withHostingWindow { [weak windowTracker] window in
            windowTracker?.current = window
        }
#endif
    }
}
