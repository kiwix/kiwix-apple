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

enum PDFHandler {
    static func tempFileFrom(pdfData: Data, fileName: String) -> URL? {
        guard let tempFileName = fileName.split(separator: ".").first?.appending(".pdf") else {
            return nil
        }
        let tempFileURL = URL(temporaryFileWithName: tempFileName)
        guard (try? pdfData.write(to: tempFileURL)) != nil else {
            return nil
        }
        return tempFileURL
    }
}

#if os(iOS)
/// On receiving pdf content and a file name, it gives the ability to share it
struct SharePDFHandler: ViewModifier {

    private let sharePDF = NotificationCenter.default.publisher(for: .sharePDF)
    @State private var temporaryURL: URL?

    func body(content: Content) -> some View {
        content.onReceive(sharePDF) { notification in

            guard let userInfo = notification.userInfo,
                  let pdfData = userInfo["data"] as? Data,
                  let fileName = userInfo["fileName"] as? String,
                  let tempURL = PDFHandler.tempFileFrom(pdfData: pdfData, fileName: fileName) else {
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
