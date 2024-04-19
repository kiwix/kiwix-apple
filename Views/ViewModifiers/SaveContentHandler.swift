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
                  url.isKiwixURL else {
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
            Alert(title: Text("common.export_file.alert.title".localized),
                  message: Text("common.export_file.alert.description"
                        .localizedWithFormat(withArgs: kiwixURL?.lastPathComponent ?? "")
                  ),
                  primaryButton: .default(Text("common.export_file.alert.button.title")) {
                if let kiwixURL,
                   let urlContent = ZimFileService.shared.getURLContent(url: kiwixURL) {
                    urlAndContent = (kiwixURL, urlContent)
                } else {
                    urlAndContent = nil
                }
                kiwixURL = nil
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
            if case .OK = response,
               let urlContent = ZimFileService.shared.getURLContent(url: url),
               let destinationURL = savePanel.url {
                try? urlContent.data.write(to: destinationURL)
                savePanel.close()
            }
        }
    }
    #endif
}

#if os(iOS)
struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    @Environment(\.dismiss) var dismissAction
    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.modalPresentationStyle = .pageSheet
        controller.completionWithItemsHandler = { (_, _, _, _) in
            self.dismissAction()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

#endif

extension URL {
    fileprivate func tempFileURL() -> URL? {
        let directory = FileManager.default.temporaryDirectory
        if #available(macOS 13.0, iOS 16.0, *) {
            return directory.appending(path: lastPathComponent)
        } else {
            return directory.appendingPathComponent(lastPathComponent)
        }
    }
}
