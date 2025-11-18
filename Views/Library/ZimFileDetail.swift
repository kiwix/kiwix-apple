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
    @State private var isPresentingValidationAlert = false
    @State private var isInDocumentsDirectory = false
    let dismissParent: (() -> Void)? // iOS only

    init(zimFile: ZimFile, dismissParent: (() -> Void)?) {
        self.zimFile = zimFile
        self.dismissParent = dismissParent
    }

    var body: some View {
        #if os(macOS)
        List {
            Section(LocalString.zim_file_list_name_text) { Text(zimFile.name).lineLimit(nil) }.collapsible(false)
            Section(LocalString.zim_file_list_description_text) {
                Text(zimFile.fileDescription).lineLimit(nil)
            }.collapsible(false)
            Section(LocalString.zim_file_list_actions_text) { actions }.collapsible(false)
            Section(LocalString.zim_file_list_info_text) {
                basicInfo
                boolInfo
                counts
                id
            }.collapsible(false)
            if isValidatable(zimFile) {
                Section { validateSection }
                    .collapsible(false)
            }
            if isDestroyable(zimFile) {
                Section {
                    destorySection
                }.collapsible(false)
            }
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
            if isValidatable(zimFile) {
                Section { validateSection }
            }
            if isDestroyable(zimFile) {
                Section { destorySection }
            }
        }
        .listStyle(.insetGrouped)
        .modifier(FileLocator(isPresenting: $isPresentingFileLocator))
        .navigationTitle(zimFile.name)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(zimFile.publisher(for: \.fileURLBookmark)) { _ in
            Task { @MainActor in
                if let zimFileName = await ZimFileService.shared.getFileURL(
                    zimFileID: zimFile.fileID
                )?.lastPathComponent,
                   let documentDirectoryURL = FileManager.default.urls(
                    for: .documentDirectory, in: .userDomainMask
                   ).first,
                   FileManager.default.fileExists(
                    atPath: documentDirectoryURL.appendingPathComponent(zimFileName).path
                   ) {
                    isInDocumentsDirectory = true
                } else {
                    isInDocumentsDirectory = false
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private var actions: some View {
        if zimFile.downloadTask != nil {  // zim file is being downloaded
            DownloadTaskDetail(downloadZimFile: zimFile)
        } else if zimFile.isMissing {  // zim file was opened, but is now missing
            Action(title: LocalString.zim_file_action_locate_title) { isPresentingFileLocator = true }
        } else if zimFile.fileURLBookmark != nil {  // zim file is opened
            Action(title: LocalString.zim_file_action_open_main_page_title) {
                guard let url = await ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return }
                NotificationCenter.openURL(url, inNewTab: true)
                #if os(iOS)
                dismissParent?()
                #endif
            }
            #if os(macOS)
            .buttonStyle(.borderedProminent)
            #endif
            #if os(macOS)
            Action(title: LocalString.zim_file_action_reveal_in_finder_title) {
                guard let url = await ZimFileService.shared.getFileURL(zimFileID: zimFile.id) else { return }
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            #endif
        } else if zimFile.downloadURL != nil {  // zim file can be downloaded
            #if os(iOS)
            Toggle(LocalString.zim_file_action_toggle_cellular, isOn: $downloadUsingCellular)
            #endif
            downloadAction
        }
    }
    
    private func isValidatable(_ zimFile: ZimFile) -> Bool {
        zimFile.fileURLBookmark != nil && !zimFile.isMissing
    }
    
    @ViewBuilder
    private var validateSection: some View {
        Action(title: "Validate") {
            isPresentingValidationAlert = true
        }.alert(isPresented: $isPresentingValidationAlert) {
            Alert(
                title: Text("Validation takes a long time"),
                message: Text("To make sure your ZIM file is fully in tact, it can be verified. Caution: It may take several minutes to completely validate a ZIM file and you won't be able to use Kiwix in the meantime."),
                primaryButton: .default(Text("Validate")) {
                    Task {
                        Log.LibraryOperations.notice("Started ZIM validation for \(zimFile.fileID.uuidString, privacy: .public)")
                        NotificationCenter.startValidateZIM(title: zimFile.name)
                        let result = await ZimFileService.shared.isValidZim(zimFileID: zimFile.fileID)
                        Log.LibraryOperations.notice("Completed ZIM validation for \(zimFile.fileID.uuidString, privacy: .public), success: \(result, privacy: .public)")
                        NotificationCenter.stopValidation()
                        await MainActor.run {
                            zimFile.isValidated = true
                            let viewContext = Database.shared.viewContext
                            if viewContext.hasChanges {
                                try? viewContext.save()
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func isDestroyable(_ zimFile: ZimFile) -> Bool {
        if zimFile.isMissing { return true }
        if zimFile.fileURLBookmark != nil { return true }
        return false
    }
    
    @ViewBuilder
    private var destorySection: some View {
#if os(macOS)
        unlinkAction
#elseif os(iOS)
        if isInDocumentsDirectory {
            deleteAction
        } else {
            unlinkAction
        }
#endif
    }

    @ViewBuilder
    private var unlinkAction: some View {
        Action(title: LocalString.zim_file_action_unlink_title, isDestructive: true) {
            isPresentingUnlinkAlert = true
        }.alert(isPresented: $isPresentingUnlinkAlert) {
            Alert(
                title: Text(LocalString.zim_file_action_unlink_title + " " + zimFile.name),
                message: Text(LocalString.zim_file_action_unlink_message),
                primaryButton: .destructive(Text(LocalString.zim_file_action_unlink_button_title)) {
                    Task {
                        await LibraryOperations.unlink(zimFileID: zimFile.fileID)
                        #if os(iOS)
                        dismiss()
                        #endif
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    @ViewBuilder
    private var deleteAction: some View {
        Action(title: LocalString.zim_file_action_delete_title, isDestructive: true) {
            isPresentingDeleteAlert = true
        }.alert(isPresented: $isPresentingDeleteAlert) {
            Alert(
                title: Text(LocalString.zim_file_action_delete_title + " " + zimFile.name),
                message: Text(LocalString.zim_file_action_delete_message),
                primaryButton: .destructive(Text(LocalString.zim_file_action_delete_button_title)) {
                    Task {
                        await LibraryOperations.delete(zimFileID: zimFile.fileID)
                        #if os(iOS)
                        dismiss()
                        #endif
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var downloadAction: some View {
        Action(title: LocalString.zim_file_action_download_title) {
            if let freeSpace = freeSpace, zimFile.size >= freeSpace - 10^9 {
                isPresentingDownloadAlert = true
            } else {
                DownloadService.shared.start(zimFileID: zimFile.id, allowsCellularAccess: downloadUsingCellular)
            }
        }.alert(isPresented: $isPresentingDownloadAlert) {
            Alert(
                title: Text(LocalString.zim_file_action_download_warning_title),
                message: Text({
                    if let freeSpace = freeSpace, zimFile.size > freeSpace {
                        return LocalString.zim_file_action_download_warning_message
                    } else {
                        return LocalString.zim_file_action_download_warning_message1
                    }
                }()),
                primaryButton: .default(Text(LocalString.zim_file_action_download_button_anyway)) {
                    DownloadService.shared.start(
                        zimFileID: zimFile.id,
                        allowsCellularAccess: downloadUsingCellular
                    )
                },
                secondaryButton: .cancel()
            )
        }
        #if os(macOS)
        .buttonStyle(.borderedProminent)
        #endif
    }

    @ViewBuilder
    private var basicInfo: some View {
        Attribute(title: LocalString.zim_file_base_info_attribute_language,
                  detail: zimFile.languageCodesListed)
        Attribute(title: LocalString.zim_file_base_info_attribute_category,
                  detail: Category(rawValue: zimFile.category)?.name)
        Attribute(title: LocalString.zim_file_base_info_attribute_size,
                  detail: Formatter.size.string(fromByteCount: zimFile.size))
        Attribute(title: LocalString.zim_file_base_info_attribute_created,
                  detail: Formatter.dateMedium.string(from: zimFile.created))
    }

    @ViewBuilder
    private var boolInfo: some View {
        AttributeBool(title: LocalString.zim_file_bool_info_pictures, detail: zimFile.hasPictures)
        AttributeBool(title: LocalString.zim_file_bool_info_videos, detail: zimFile.hasVideos)
        AttributeBool(title: LocalString.zim_file_bool_info_details, detail: zimFile.hasDetails)
        if zimFile.requiresServiceWorkers {
            AttributeBool(title: LocalString.zim_file_bool_info_require_service_workers,
                          detail: zimFile.requiresServiceWorkers)
        }
        AttributeBool(title: "Validated", detail: zimFile.isValidated)
    }

    @ViewBuilder
    private var counts: some View {
        Attribute(
            title: LocalString.zim_file_counts_article_count,
            detail: Formatter.number.string(from: NSNumber(value: zimFile.articleCount))
        )
        Attribute(
            title: LocalString.zim_file_counts_article_media_count,
            detail: Formatter.number.string(from: NSNumber(value: zimFile.mediaCount))
        )
    }

    @ViewBuilder
    private var id: some View {
        Attribute(title: LocalString.zim_file_detail_id_title, detail: String(zimFile.fileID.uuidString.prefix(8)))
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
    @EnvironmentObject var selection: SelectedZimFileViewModel
    @State private var downloadState = DownloadState.empty()

    var body: some View {
        Group {
            Action(title: LocalString.zim_file_download_task_action_title_cancel, isDestructive: true) {
                DownloadService.shared.cancel(zimFileID: downloadZimFile.fileID)
                selection.reset()
            }
            if let error = downloadZimFile.downloadTask?.error {
                if downloadState.resumeData != nil {
                    Action(title: LocalString.zim_file_download_task_action_try_recover) {
                        DownloadService.shared.resume(zimFileID: downloadZimFile.fileID)
                    }
                }
                Attribute(title: LocalString.zim_file_download_task_action_failed, detail: detail)
                Text(error)
            } else if downloadState.resumeData == nil {
                Action(title: LocalString.zim_file_download_task_action_pause) {
                    DownloadService.shared.pause(zimFileID: downloadZimFile.fileID)
                }
                Attribute(title: LocalString.zim_file_download_task_action_downloading, detail: detail)
            } else {
                Action(title: LocalString.zim_file_download_task_action_resume) {
                    DownloadService.shared.resume(zimFileID: downloadZimFile.fileID)
                }
                Attribute(title: LocalString.zim_file_download_task_action_paused, detail: detail)
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

    private var detail: String {
        if let percent = percent {
            return "\(size) - \(percent)"
        } else {
            return size
        }
    }

    private var size: String {
        Formatter.size.string(fromByteCount: downloadState.downloaded)
    }

    private var percent: String? {
        guard downloadState.total > 0 else { return nil }
        let fractionCompleted = NSNumber(value: Double(downloadState.downloaded) / Double(downloadState.total))
        return Formatter.percent.string(from: fractionCompleted)
    }
}

private struct ServiceWorkerWarning: View {
    var body: some View {
        Label {
            Text(LocalString.service_worker_warning_label_description)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill").renderingMode(.original)
        }
    }
}
