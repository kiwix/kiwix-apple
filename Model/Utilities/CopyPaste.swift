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

enum CopyPaste {
    public static func copyToPasteBoard(url: URL) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #else
        UIPasteboard.general.setValue(url.absoluteString, forPasteboardType: UTType.url.identifier)
        #endif
    }
    
    public static func copyToPasteBoard(image: CGImage) {
        #if os(iOS)
        UIPasteboard.general.image = UIImage(cgImage: image)
        #else
        NSPasteboard.general.clearContents()
        let size = CGSize(width: image.width, height: image.height)
        let nsImage = NSImage(cgImage: image, size: size)
        let tiffData = nsImage.tiffRepresentation
        NSPasteboard.general.setData(tiffData, forType: .tiff)
        #endif
    }
}
