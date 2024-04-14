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

/// On receiving pdf content and a file name, it gives the ability to share it
struct SharePDFHandler: ViewModifier {

    private let sharePDF = NotificationCenter.default.publisher(for: .sharePDF)
    @State private var temporaryURL: URL?

    func body(content: Content) -> some View {
        content.onReceive(sharePDF) { notification in

            guard let userInfo = notification.userInfo,
                  let pdfData = userInfo["data"] as? Data,
                  let fileName = userInfo["fileName"] as? String,
                  let tempFileName = fileName.split(separator: ".").first?.appending(".pdf") else {
                return
            }

            let tempFileURL = URL(temporaryFileWithName: tempFileName)
            guard (try? pdfData.write(to: tempFileURL)) != nil else {
                temporaryURL = nil
                return
            }
            temporaryURL = tempFileURL
        }
        #if os(iOS)
        .sheet(
            isPresented: Binding<Bool>.constant($temporaryURL.wrappedValue != nil),
            onDismiss: {
                if let temporaryURL {
                    try? FileManager.default.removeItem(at: temporaryURL)
                }
                temporaryURL = nil
            }, content: {
                #if os(iOS)
                ActivityViewController(activityItems: [temporaryURL].compactMap { $0 })
                #else
                NSSharingServicePicker(items: [temporaryURL])
                #endif
            }
        )
        #else
        .background(SharingsPicker(
            isPresented: Binding<Bool>.constant($temporaryURL.wrappedValue != nil),
            sharingItems: [temporaryURL].compactMap { $0 },
            onDismiss: {
                temporaryURL = nil
            }
        ))
        #endif
    }
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

#if os(macOS)
struct SharingsPicker: NSViewRepresentable {
    @Binding var isPresented: Bool {
        didSet {
            if isPresented == false {
                onDismiss?()
            }
        }
    }
    var sharingItems: [Any] = []
    let onDismiss: (() -> Void)?

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            let picker = NSSharingServicePicker(items: sharingItems)
            picker.delegate = context.coordinator
            DispatchQueue.main.async { // call async, to not to block updates
                picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minX)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        let owner: SharingsPicker

        init(owner: SharingsPicker) {
            self.owner = owner
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            sharingServicePicker.delegate = nil   // << cleanup
            owner.isPresented = false        // << dismiss
            owner.onDismiss?()
        }
    }
}
#endif
