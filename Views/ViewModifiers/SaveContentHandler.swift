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

/// On receiving a Kiwix URL, it offers to save the content of it as a file
struct SaveContentHandler: ViewModifier {

    private let saveContentToFile = NotificationCenter.default.publisher(for: .saveContent)

    func body(content: Content) -> some View {
        content.onReceive(saveContentToFile) { notification in
            guard let url = notification.userInfo?["url"] as? URL,
                  url.isKiwixURL else {
                return
            }
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.nameFieldStringValue = url.lastPathComponent
            savePanel.begin { (response: NSApplication.ModalResponse) in
                if case .OK = response,
                   let urlContent = ZimFileService.shared.getURLContent(url: url),
                   let destinationURL = savePanel.url {
                    try? urlContent.data.write(to: destinationURL)
                }
            }
            #endif
        }
    }
}
