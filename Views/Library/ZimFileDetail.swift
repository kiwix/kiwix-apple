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

import Combine
import CoreData
import SwiftUI
import UniformTypeIdentifiers

import Defaults

/// Detail about one single zim file.
struct ZimFileDetail: View {
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigation: NavigationViewModel
    @ObservedObject var zimFile: ZimFile
    @State private var isPresentingDeleteAlert = false
    @State private var isPresentingDownloadAlert = false
    @State private var isPresentingFileLocator = false
    @State private var isPresentingUnlinkAlert = false
    @State private var isInDocumentsDirectory = false
    let dismissParent: (() -> Void)? // iOS only

    init(zimFile: ZimFile, dismissParent: (() -> Void)?) {
        self.zimFile = zimFile
        self.dismissParent = dismissParent
    }

    var body: some View {
        #if os(macOS)
        List {
            Section("zim_file.list.name.text".localized) { Text(zimFile.name).lineLimit(nil) }.collapsible(false)
            Section("zim_file.list.description.text".localized) {
                Text(zimFile.fileDescription).lineLimit(nil)
            }.collapsible(false)
            Section("zim_file.list.actions.text".localized) { actions }.collapsible(false)
            Section("zim_file.list.info.text".localized) {
                basicInfo
                boolInfo
                counts
                id
            }.collapsible(false)
        }
        .safeAreaInset(edge: .top) {
            if zimFile.requiresServiceWorkers {
                VStack(spacing: 0) {
                    ServiceWorkerWarning().padding(6)
                    Divider()
                }.background(.regularMaterial)
            }
        }
        .listStyle(.sidebar)
        .modifier(FileLocator(isPresenting: $isPresentingFileLocator))
        #elseif os(iOS)
        List {
            Section {
                Text(zimFile.name).lineLimit(nil)
                Text(zimFile.fileDescription).lineLimit(nil)
            }
            Section {
                actions.alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            }
            Section { basicInfo }
            Section {
                boolInfo
            } footer: {
                if zimFile.requiresServiceWorkers {
                    ServiceWorkerWarning()
                }
            }
            Section { counts }
            Section { id }
        }
        .listStyle(.insetGrouped)
        .modifier(FileLocator(isPresenting: $isPresentingFileLocator))
        .navigationTitle(zimFile.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let zimFileName = await ZimFileService.shared.getFileURL(zimFileID: zimFile.fileID)?.lastPathComponent,
               let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
               FileManager.default.fileExists(atPath: documentDirectoryURL.appendingPathComponent(zimFileName).path) {
                isInDocumentsDirectory = true
            } else {
                isInDocumentsDirectory = false
            }
        }
        #endif
    }

    @ViewBuilder
    var actions: some View {
        if zimFile.downloadTask != nil {  // zim file is being downloaded
            DownloadTaskDetail(downloadZimFile: zimFile)
        } else if zimFile.isMissing {  // zim file was opened, but is now missing
            Action(title: "zim_file.action.locate.title".localized) { isPresentingFileLocator = true }
            unlinkAction
        } else if zimFile.fileURLBookmark != nil {  // zim file is opened
            Action(title: "zim_file.action.open_main_page.title".localized) {
                guard let url = await ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
                NotificationCenter.openURL(url, navigationID: navigation.uuid, inNewTab: true)
                #if os(iOS)
                dismissParent?()
                #endif
            }
            #if os(macOS)
            Action(title: "zim_file.action.reveal_in_finder.title".localized) {
                guard let url = await ZimFileService.shared.getFileURL(zimFileID: zimFile.id) else { return }
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            unlinkAction
            #elseif os(iOS)
            if isInDocumentsDirectory {
                deleteAction
            } else {
                unlinkAction
            }
            #endif
        } else if zimFile.downloadURL != nil {  // zim file can be downloaded
            #if os(iOS)
            Toggle("zim_file.action.toggle_cellular".localized, isOn: $downloadUsingCellular)
            #endif
            downloadAction
        }
    }

    var unlinkAction: some View {
        Action(title: "zim_file.action.unlink.title".localized, isDestructive: true) {
            isPresentingUnlinkAlert = true
        }.alert(isPresented: $isPresentingUnlinkAlert) {
            Alert(
                title: Text("zim_file.action.unlink.title".localized + " " + zimFile.name),
                message: Text("zim_file.action.unlink.message".localized),
                primaryButton: .destructive(Text("zim_file.action.unlink.button.title".localized)) {
                    Task {
                        let tabIds = zimFile.tabs.map { $0.objectID }
                        await LibraryOperations.unlink(zimFileID: zimFile.fileID)
                        closeZIM(zimFileId: zimFile.fileID)
                        #if os(iOS)
                        dismiss()
                        #endif
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    @MainActor
    func closeZIM(zimFileId: UUID) {
        NotificationCenter.closeZIM(zimFileId)
    }

    var deleteAction: some View {
        Action(title: "zim_file.action.delete.title".localized, isDestructive: true) {
            isPresentingDeleteAlert = true
        }.alert(isPresented: $isPresentingDeleteAlert) {
            Alert(
                title: Text("zim_file.action.delete.title".localized + " " + zimFile.name),
                message: Text("zim_file.action.delete.message".localized),
                primaryButton: .destructive(Text("zim_file.action.delete.button.title".localized)) {
                    Task {
                        await LibraryOperations.delete(zimFileID: zimFile.fileID)
                        closeZIM(zimFileId: zimFile.fileID)
                        #if os(iOS)
                        dismiss()
                        #endif
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    var downloadAction: some View {
        Action(title: "zim_file.action.download.title".localized) {
            if let freeSpace = freeSpace, zimFile.size >= freeSpace - 10^9 {
                isPresentingDownloadAlert = true
            } else {
                DownloadService.shared.start(zimFileID: zimFile.id, allowsCellularAccess: downloadUsingCellular)
            }
        }.alert(isPresented: $isPresentingDownloadAlert) {
            Alert(
                title: Text("zim_file.action.download.warning.title".localized),
                message: Text({
                    if let freeSpace = freeSpace, zimFile.size > freeSpace {
                        return "zim_file.action.download.warning.message".localized
                    } else {
                        return "zim_file.action.download.warning.message1".localized
                    }
                }()),
                primaryButton: .default(Text("zim_file.action.download.button.anyway".localized)) {
                    DownloadService.shared.start(
                        zimFileID: zimFile.id,
                        allowsCellularAccess: false
                    )
                },
                secondaryButton: .cancel()
            )
        }
    }

    @ViewBuilder
    var basicInfo: some View {
        Attribute(title: "zim_file.base_info.attribute.language".localized,
                  detail: zimFile.languageCodesListed)
        Attribute(title: "zim_file.base_info.attribute.category".localized,
                  detail: Category(rawValue: zimFile.category)?.name)
        Attribute(title: "zim_file.base_info.attribute.size".localized,
                  detail: Formatter.size.string(fromByteCount: zimFile.size))
        Attribute(title: "zim_file.base_info.attribute.created".localized,
                  detail: Formatter.dateMedium.string(from: zimFile.created))
    }

    @ViewBuilder
    var boolInfo: some View {
        AttributeBool(title: "zim_file.bool_info.pictures".localized, detail: zimFile.hasPictures)
        AttributeBool(title: "zim_file.bool_info.videos".localized, detail: zimFile.hasVideos)
        AttributeBool(title: "zim_file.bool_info.details".localized, detail: zimFile.hasDetails)
        if zimFile.requiresServiceWorkers {
            AttributeBool(title: "zim_file.bool_info.require_service_workers".localized,
                          detail: zimFile.requiresServiceWorkers)
        }
    }

    @ViewBuilder
    var counts: some View {
        Attribute(
            title: "zim_file.counts.article_count".localized,
            detail: Formatter.number.string(from: NSNumber(value: zimFile.articleCount))
        )
        Attribute(
            title: "zim_file.counts.article.media_count".localized,
            detail: Formatter.number.string(from: NSNumber(value: zimFile.mediaCount))
        )
    }

    @ViewBuilder
    var id: some View {
        Attribute(title: "zim_file.detail.id.title".localized, detail: String(zimFile.fileID.uuidString.prefix(8)))
    }

    private var freeSpace: Int64? {
        try? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage
    }
}

private struct FileLocator: ViewModifier {
    @Binding var isPresenting: Bool

    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresenting,
            allowedContentTypes: [UTType(exportedAs: "org.openzim.zim")],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            Task { await LibraryOperations.open(url: url) }
        }
    }
}

private struct DownloadTaskDetail: View {
    @ObservedObject var downloadZimFile: ZimFile
    @EnvironmentObject var viewModel: LibraryViewModel
    @State private var downloadState = DownloadState.empty()

    var body: some View {
        Group {
            Action(title: "zim_file.download_task.action.title.cancel".localized, isDestructive: true) {
                DownloadService.shared.cancel(zimFileID: downloadZimFile.fileID)
                viewModel.selectedZimFile = nil
            }
            if let error = downloadZimFile.downloadTask?.error {
                if downloadState.resumeData != nil {
                    Action(title: "zim_file.download_task.action.try_recover".localized) {
                        DownloadService.shared.resume(zimFileID: downloadZimFile.fileID)
                    }
                }
                Attribute(title: "zim_file.download_task.action.failed".localized, detail: detail)
                Text(error)
            } else if downloadState.resumeData == nil {
                Action(title: "zim_file.download_task.action.pause".localized) {
                    DownloadService.shared.pause(zimFileID: downloadZimFile.fileID)
                }
                Attribute(title: "zim_file.download_task.action.downloading".localized, detail: detail)
            } else {
                Action(title: "zim_file.download_task.action.resume".localized) {
                    DownloadService.shared.resume(zimFileID: downloadZimFile.fileID)
                }
                Attribute(title: "zim_file.download_task.action.paused".localized, detail: detail)
            }
        }.onReceive(
            DownloadService.shared.progress.publisher
                .compactMap { [self] (states: [UUID: DownloadState]) -> DownloadState? in
                    return states[downloadZimFile.fileID]
                }, perform: { [self] (state: DownloadState?) in
                    if let state {
                        self.downloadState = state
                    }
                }
        )
    }

    var detail: String {
        if let percent = percent {
            return "\(size) - \(percent)"
        } else {
            return size
        }
    }

    var size: String {
        Formatter.size.string(fromByteCount: downloadState.downloaded)
    }

    var percent: String? {
        guard downloadState.total > 0 else { return nil }
        let fractionCompleted = NSNumber(value: Double(downloadState.downloaded) / Double(downloadState.total))
        return Formatter.percent.string(from: fractionCompleted)
    }
}

private struct Action: View {
    let title: String
    let isDestructive: Bool
    let action: @MainActor () async -> Void

    init(title: String,
         isDestructive: Bool = false,
         action: @MainActor @escaping () async -> Void = {}
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        AsyncButton(action: action, label: {
            HStack {
                Spacer()
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : nil)
                Spacer()
            }
        })
    }
}

private struct ServiceWorkerWarning: View {
    var body: some View {
        Label {
            Text("service_worker_warning.label.description".localized)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill").renderingMode(.original)
        }
    }
}

struct ZimFileDetail_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 1000000
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.downloadURL = URL(string: "https://www.example.com")
        zimFile.fileID = UUID()
        zimFile.fileDescription = "A very long description"
        zimFile.flavor = "max"
        zimFile.hasDetails = true
        zimFile.hasPictures = false
        zimFile.hasVideos = true
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia Zim File Name"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        return zimFile
    }()

    static var previews: some View {
        ZimFileDetail(zimFile: zimFile, dismissParent: nil).frame(width: 300).previewLayout(.sizeThatFits)
    }
}
