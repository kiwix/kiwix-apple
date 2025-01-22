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

    @EnvironmentObject private var browser: BrowserViewModel

    /// - Returns: Returns the browser data, fileName and extension
    private func dataNameAndExtension() async -> FileExportData? {
        guard let fileName = browser.webView.url?.lastPathComponent else {
            return nil
        }
        guard let (pageData, fileExtension) = await browser.pageDataWithExtension() else {
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
                #if os(iOS)
                guard let exportData = await dataNameAndExtension() else { return }
                NotificationCenter.exportFileData(exportData)
                #else
                guard let url = await tempFileURL() else { return }
                NSSharingServicePicker(items: [url]).show(relativeTo: .null, of: browser.webView, preferredEdge: .minY)
                #endif
            }
        } label: {
            Label {
                Text(LocalString.common_button_share)
            }  icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }.disabled(browser.zimFileName.isEmpty)
    }
}
