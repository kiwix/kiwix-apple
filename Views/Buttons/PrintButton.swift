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

#if os(macOS)
import SwiftUI
import PDFKit

struct PrintButton: View {
    @FocusedValue(\.isBrowserURLSet) var isBrowserURLSet
    let browser: BrowserViewModel

    private static func dataAndName(browser: BrowserViewModel) async -> (Data, String)? {
        guard let browserURLName = browser.webView.url?.lastPathComponent else {
            return nil
        }
        guard let pdfData = try? await browser.webView.pdf() else {
            return nil
        }
        return (pdfData, browserURLName)
    }

    private func tempFileURL(browser: BrowserViewModel) async -> URL? {
        guard let (pdfData, browserURLName) = await Self.dataAndName(browser: browser) else { return nil }
        return FileExporter.tempFileFrom(exportData: .init(data: pdfData, fileName: browserURLName))
    }

    var body: some View {
        Button { [weak browser] in
            Task { [weak browser] in
                guard let browser,
                        let url = await tempFileURL(browser: browser) else { return }
                let pdfDoc = PDFDocument(url: url)
                let operation = pdfDoc?.printOperation(for: .shared, scalingMode: .pageScaleToFit, autoRotate: true)
                operation?.run()
            }
        } label: {
            Label {
                Text(LocalString.common_button_print)
            }  icon: {
                Image(systemName: "printer")
            }
        }.disabled(isBrowserURLSet != true)
        .keyboardShortcut("p", modifiers: .command)
    }
}
#endif
