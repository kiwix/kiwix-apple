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
    #if os(iOS)
    @State private var kiwixURL: URL?
    @State private var urlAndContent: (URL, URLContent)?
    #endif

    func body(content: Content) -> some View {
        content.onReceive(saveContentToFile) { notification in
            guard let url = notification.userInfo?["url"] as? URL,
                  url.isZIMURL else {
                return
            }
            #if os(macOS)
            savePanelFor(url: url)
            #else
            kiwixURL = url
            #endif
        }
#if os(iOS)
        .alert(isPresented: Binding<Bool>.constant($kiwixURL.wrappedValue != nil)) {
            Alert(title: Text(LocalString.common_export_file_alert_title),
                  message: Text(
                    LocalString.common_export_file_alert_description(withArgs: kiwixURL?.lastPathComponent ?? "")
                  ),
                  primaryButton: .default(Text(LocalString.common_export_file_alert_button_title)) {
                Task { @MainActor in
                    if let kiwixURL,
                       let urlContent = await ZimFileService.shared.getURLContent(url: kiwixURL) {
                        urlAndContent = (kiwixURL, urlContent)
                    } else {
                        urlAndContent = nil
                    }
                    kiwixURL = nil
                }
            },
                  secondaryButton: .cancel {
                kiwixURL = nil
            }
            )
        }
        .sheet(
            isPresented: Binding<Bool>.constant($urlAndContent.wrappedValue != nil),
            onDismiss: {
                if let (url, _) = urlAndContent,
                   let tempURL = url.tempFileURL() {
                    try? FileManager.default.removeItem(at: tempURL)
                }
                urlAndContent = nil
            }, content: {
                if let (url, urlContent) = urlAndContent {
                    if let tempURL = url.tempFileURL(),
                       (try? urlContent.data.write(to: tempURL)) != nil {
                        ActivityViewController(activityItems: [tempURL])
                    }
                }
            }
        )
#endif
    }

    #if os(macOS)
    private func savePanelFor(url: URL) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = url.lastPathComponent
        savePanel.begin { (response: NSApplication.ModalResponse) in
            Task { @MainActor in
                if case .OK = response,
                   let urlContent = await ZimFileService.shared.getURLContent(url: url),
                   let destinationURL = savePanel.url {
                    try? urlContent.data.write(to: destinationURL)
                    savePanel.close()
                }
            }
        }
    }
    #endif
}

extension URL {
    fileprivate func tempFileURL() -> URL? {
        let directory = FileManager.default.temporaryDirectory
        return directory.appending(path: lastPathComponent)
    }
}
