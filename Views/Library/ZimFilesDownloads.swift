import CoreData
import SwiftUI
import ActivityKit

/// A grid of zim files that are being downloaded.
struct ZimFilesDownloads: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadTask.created, ascending: false)],
        animation: .easeInOut
    ) private var downloadTasks: FetchedResults<DownloadTask>
    private let dismiss: (() -> Void)?

    init(dismiss: (() -> Void)?) {
        self.dismiss = dismiss
    }

    var body: some View {
        LazyVGrid(
            columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(downloadTasks) { downloadTask in
                if let zimFile = downloadTask.zimFile {
                    DownloadTaskCell(zimFile).modifier(LibraryZimFileContext(zimFile: zimFile, dismiss: dismiss))
                }
            }
        }
        .modifier(GridCommon())
        .modifier(ToolbarRoleBrowser())
        .navigationTitle(NavigationItem.downloads.name)
        .overlay {
            if downloadTasks.isEmpty {
                Message(text: "zim_file_downloads.overlay.empty.message".localized)
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if #unavailable(iOS 16), horizontalSizeClass == .regular {
                    Button {
                        NotificationCenter.toggleSidebar()
                    } label: {
                        Label("zim_file_downloads.toolbar.show_sidebar.label".localized, systemImage: "sidebar.left")
                    }
                }
            }
            #endif
        }
        .onAppear {
            // Start Live Activity for each download task
            for downloadTask in downloadTasks {
                if let zimFile = downloadTask.zimFile {
                    let attributes = DownloadActivityAttributes(fileID: zimFile.fileID, fileName: zimFile.name)
                    let initialContentState = DownloadActivityAttributes.ContentState(progress: 0.0, speed: 0.0)
                    do {
                        _ = try Activity<DownloadActivityAttributes>.request(
                            attributes: attributes,
                            contentState: initialContentState,
                            pushType: nil
                        )
                    } catch {
                        print("Error starting Live Activity: \(error)")
                    }
                }
            }
        }
    }
}
