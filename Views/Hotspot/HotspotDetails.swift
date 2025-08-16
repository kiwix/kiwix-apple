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

struct HotspotDetails: View {
    let address: URL
    let qrCodeImage: CGImage?
    let vSpace: CGFloat
    
    private enum Const {
        static let imageWidth: CGFloat = 220
    }
    
    var body: some View {
        HotspotCell {
            VStack(alignment: .center, spacing: vSpace) {
                #if os(macOS)
                Link(address.absoluteString, destination: address)
                    .fontWeight(.semibold).foregroundColor(.accentColor).lineLimit(1)
                #else
                Text(LocalString.hotspot_server_active_warning)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                
                Text(address.absoluteString)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                #endif
                HStack {
                    ShareLink(item: address) {
                        Label(LocalString.common_button_share, systemImage: "square.and.arrow.up")
                    }
                    Spacer(minLength: 32)
                    DynamicCopyButton(action: { CopyPaste.copyToPasteBoard(url: address) })
                }
                .frame(width: Const.imageWidth)
#if os(macOS)
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
#endif
            }
        }
        
        HotspotCell {
            HStack {
                Spacer()
                VStack(spacing: vSpace) {
                    Group {
                        if let qrCodeImage {
                            Image(qrCodeImage, scale: 1, label: Text(address.absoluteString))
                                .resizable()
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                    .frame(width: Const.imageWidth, height: Const.imageWidth)
                    .aspectRatio(1.0, contentMode: .fill)
                    
                    if let qrCodeImage {
                        HStack {
                            let img = Image(qrCodeImage, scale: 1, label: Text(address.absoluteString))
                            ShareLink(
                                item: img,
                                preview: SharePreview(address.absoluteString, image: img)
                            ) {
                                Label(
                                    LocalString.common_button_share,
                                    systemImage: "square.and.arrow.up"
                                )
                            }
                            Spacer(minLength: 32)
                            DynamicCopyButton(action: { CopyPaste.copyToPasteBoard(image: qrCodeImage) })
                        }
                        .frame(width: Const.imageWidth)
                    }
                }
                Spacer()
            }
#if os(macOS)
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
#endif
        }
        
        HotspotCell {
            HotspotExplanation()
        }
    }
}
