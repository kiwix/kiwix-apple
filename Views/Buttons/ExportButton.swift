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

struct ExportButton: View {
    
    #if os(macOS)
    let relativeToView: NSView
    #endif
    let webViewURL: URL?
    let pageDataWithExtension: () async -> (Data, String?)?
    let isButtonDisabled: Bool
    var actionCallback: () -> Void = { }
    
    var buttonLabel: String = LocalString.common_button_share

    /// - Returns: Returns the browser data, fileName and extension
    private func dataNameAndExtension() async -> FileExportData? {
        guard let fileName = webViewURL?.lastPathComponent else {
            return nil
        }
        guard let (pageData, fileExtension) = await pageDataWithExtension() else {
            return nil
        }
        return FileExportData(data: pageData, fileName: fileName, fileExtension: fileExtension)
    }

    private func tempFileURL() async -> URL? {
        guard let exportData = await dataNameAndExtension() else { return nil }
        return FileExporter.tempFileFrom(exportData: exportData)
    }

    var body: some View {
        Button {
            Task {
                actionCallback()
                #if os(iOS)
                guard let exportData = await dataNameAndExtension() else { return }
                NotificationCenter.exportFileData(exportData)
                #else
                guard let url = await tempFileURL() else { return }
                NSSharingServicePicker(items: [url]).show(
                    relativeTo: NSRect(
                        origin: .zero,
                        size: CGSize(
                            width: 640,
                            height: 54
                        )
                    ),
                    of: relativeToView,
                    preferredEdge: .minY
                )
                #endif
            }
        } label: {
            Label {
                Text(buttonLabel)
            }  icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }.disabled(isButtonDisabled)
    }
}
