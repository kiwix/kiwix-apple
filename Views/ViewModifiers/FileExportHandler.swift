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

#if os(iOS)
/// On receiving FileExportData, it gives the ability to share it
struct FileExportHandler: ViewModifier {

    private let shareFileData = NotificationCenter.default.publisher(for: .shareFileData)
    @State private var temporaryURL: URL?

    func body(content: Content) -> some View {
        content.onReceive(shareFileData) { notification in

            guard let userInfo = notification.userInfo,
                  let exportData = userInfo["data"] as? FileExportData,
                  let tempURL = FileExporter.tempFileFrom(exportData: exportData) else {
                temporaryURL = nil
                return
            }
            temporaryURL = tempURL
        }
        .sheet(
            isPresented: Binding<Bool>.constant($temporaryURL.wrappedValue != nil),
            onDismiss: {
                if let temporaryURL {
                    try? FileManager.default.removeItem(at: temporaryURL)
                }
                temporaryURL = nil
            }, content: {
                ActivityViewController(activityItems: [temporaryURL].compactMap { $0 })
            }
        )
    }
}
#endif
