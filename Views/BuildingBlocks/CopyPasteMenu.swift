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

struct CopyPasteMenu: View {
    
    private let url: URL
    private let label: String
    
    init(url: URL, label: String = LocalString.library_zim_file_context_copy_url) {
        self.url = url
        self.label = label
    }
    
    var body: some View {
        Button {
            #if os(macOS)
            Self.copyToPasteBoard(url: url)
            #elseif os(iOS)
            UIPasteboard.general.setValue(url.absoluteString, forPasteboardType: UTType.url.identifier)
            #endif
        } label: {
            Label(label, systemImage: "doc.on.doc")
        }
    }
    
    #if os(macOS)
    public static func copyToPasteBoard(url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }
    #endif
}

struct CopyImageToPasteBoard: View {
    private let image: CGImage
    private let label: String
    
    init(image: CGImage, label: String = LocalString.common_button_copy) {
        self.image = image
        self.label = label
    }
    
    var body: some View {
        Button {
            Self.copyToPasteBoard(image: image)
        } label: {
            Label(label, systemImage: "doc.on.doc")
        }
    }
    
    #if os(iOS)
    public static func copyToPasteBoard(image: CGImage) {
        UIPasteboard.general.image = UIImage(cgImage: image)
    }
    #endif
    
    #if os(macOS)
    public static func copyToPasteBoard(image: CGImage) {
        NSPasteboard.general.clearContents()
        let nsImage = NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height))
        let tiffData = nsImage.tiffRepresentation
        NSPasteboard.general.setData(tiffData, forType: .tiff)
    }
    #endif
}
