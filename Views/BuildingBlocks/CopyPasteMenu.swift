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
    @State var copyComplete: UInt = 0
    
    init(url: URL, label: String = LocalString.library_zim_file_context_copy_url) {
        self.url = url
        self.label = label
    }
    
    var body: some View {
        SensoryFeedbackContext({
            Button {
                #if os(macOS)
                Self.copyToPasteBoard(url: url)
                #elseif os(iOS)
                UIPasteboard.general.setValue(url.absoluteString, forPasteboardType: UTType.url.identifier)
                #endif
                copyComplete += 1
            } label: {
                Label(label, systemImage: "doc.on.doc")
            }
        }, trigger: copyComplete)
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
    @State private var copyComplete: UInt = 0
    
    init(image: CGImage, label: String = LocalString.common_button_copy) {
        self.image = image
        self.label = label
    }
    
    var body: some View {
        SensoryFeedbackContext({
            Button {
                Self.copyToPasteBoard(image: image)
                copyComplete += 1
            } label: {
                Label(label, systemImage: "doc.on.doc")
            }
        }, trigger: copyComplete)
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

struct SensoryFeedbackContext<Content: View, T: Equatable>: View {
    private let content: Content
    private let trigger: T
    
    init(@ViewBuilder _ content: () -> Content, trigger: T) {
        self.content = content()
        self.trigger = trigger
    }
    
    var body: some View {
        if #available(iOS 17, macOS 14, *) {
            content
            #if os(iOS)
                .sensoryFeedback(.success, trigger: trigger) { _, _ in true }
            #endif
        } else {
            content
        }
    }
}
