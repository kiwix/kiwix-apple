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

/// Button that presents a file importer.
/// Note 1: On iOS/iPadOS 15, fileimporter's isPresented binding is not reset to false if user swipe to dismiss the sheet.
///     In order to mitigate the issue, the binding is set to false then true with a 0.1s delay.
/// Note 2: Does not work on iOS / iPadOS via commands.
/// Note 3: Does not allow multiple selection, because we want a new tab to be opened with main page when file is opened,
///     and the multitab implementation on iOS / iPadOS does not support open multiple tabs with an url right now.
struct OpenFileButton<Label: View>: View {
    @State private var isPresented: Bool = false

    let context: OpenFileContext
    let label: Label

    init(context: OpenFileContext, @ViewBuilder label: () -> Label) {
        self.context = context
        self.label = label()
    }

    var body: some View {
        Button {
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPresented = true
            }
        } label: { label }
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [UTType.zimFile],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result else { return }
            NotificationCenter.openFiles(urls, context: context)
        }
        .help("import-open-zim-file".localized)
        .keyboardShortcut("o")
    }
}


struct OpenFileHandler: ViewModifier {
    @State private var isAlertPresented = false
    @State private var activeAlert: ActiveAlert?

    private let importFiles = NotificationCenter.default.publisher(for: .openFiles)

    enum ActiveAlert {
        case unableToOpen(filenames: [String])
    }

    func body(content: Content) -> some View {
        content.onReceive(importFiles) { notification in
            guard let urls = notification.userInfo?["urls"] as? [URL],
                  let context = notification.userInfo?["context"] as? OpenFileContext else { return }

            // try open zim files
            var openedZimFileIDs = Set<UUID>()
            var invalidURLs = Set<URL>()
            for url in urls {
                if let metadata = LibraryOperations.open(url: url) {
                    openedZimFileIDs.insert(metadata.fileID)
                } else {
                    invalidURLs.insert(url)
                }
            }

            // action for zim files that can be opened (e.g. open main page)
            switch context {
            case .command, .file:
                openedZimFileIDs.forEach { fileID in
                    guard let url = ZimFileService.shared.getMainPageURL(zimFileID: fileID) else { return }
                    #if os(macOS)
                    if .command == context {
                        NotificationCenter.openURL(url, inNewTab: true)
                    }
                    #elseif os(iOS)
                    NotificationCenter.openURL(url, inNewTab: true)
                    #endif
                }
            case .onBoarding:
                openedZimFileIDs.forEach { fileID in
                    guard let url = ZimFileService.shared.getMainPageURL(zimFileID: fileID) else { return }
                    NotificationCenter.openURL(url)
                }
            default:
                break
            }

            // show alert if there are any files that cannot be opened
            if !invalidURLs.isEmpty {
                isAlertPresented = true
                activeAlert = .unableToOpen(filenames: invalidURLs.map({ $0.lastPathComponent }))
            }
        }.alert("file_import.alert.no_open.title".localized,
                isPresented: $isAlertPresented, presenting: activeAlert) { _ in
        } message: { alert in
            switch alert {
            case .unableToOpen(let filenames):
                let name = ListFormatter.localizedString(byJoining: filenames)
                Text("file_import.alert.no_open.message".localizedWithFormat(withArgs: name))
            }
        }
    }
}
