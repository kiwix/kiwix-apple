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

import CoreData
import Defaults
import SwiftUI

/// Action row in the ZIM file details, shown when a newer version of a downloaded ZIM file is available.
/// Lets the user choose between keeping the current copy until the download finishes,
/// or deleting it first to free up space.
struct ZimFileUpdateAction: View {
    @Default(.zimUpdatesAvailable) private var updates
    @Default(.pendingZimReplacements) private var pendingReplacements
    @ObservedObject var zimFile: ZimFile
    let downloadUsingCellular: Bool
    @State private var isPresentingChoice = false
    @State private var isPresentingDeleteFirstConfirmation = false
    @State private var preselected: ZimUpdateStrategy?
    @State private var canProceed = true
    @State private var canDeleteOld = true
    @State private var freeSpace: Int64?
    /// `DownloadTaskDetail` reads a selection model out of the environment, which only the
    /// library's side panels provide on macOS, not the Opened list this row usually appears in.
    /// It uses it to clear the selection when a download is cancelled, which is not what should
    /// happen here: this page belongs to the ZIM file being replaced, not to the download.
    /// A local model gives that call a harmless target, on every platform.
    @StateObject private var downloadSelection = SelectedZimFileViewModel()

    var body: some View {
        if let downloadingZimFile = replacementBeingDownloaded() {
            Text(LocalString.zim_file_update_downloading)
                .font(.caption)
                .foregroundColor(.secondary)
            ZimFileDetail.DownloadTaskDetail(downloadZimFile: downloadingZimFile)
                .environmentObject(downloadSelection)
        } else if let newZimFile = newerVersion() {
            Action(title: LocalString.zim_file_update_action_title) {
                freeSpace = ZimReplacement.freeSpace()
                canDeleteOld = await ZimReplacement.canDeleteFile(of: zimFile.fileID)
                preselected = ZimUpdateStrategy.preselect(
                    freeSpace: freeSpace,
                    newSize: newZimFile.size,
                    oldSize: zimFile.size,
                    canDeleteOld: canDeleteOld
                )
                canProceed = ZimUpdateStrategy.canProceed(
                    freeSpace: freeSpace,
                    newSize: newZimFile.size,
                    oldSize: zimFile.size,
                    canDeleteOld: canDeleteOld
                )
                isPresentingChoice = true
            }
            .alert(LocalString.zim_file_update_dialog_title, isPresented: $isPresentingChoice) {
                if canProceed {
                    if !canDeleteOld {
                        keepButton(newFileID: newZimFile.fileID)
                    } else if preselected == .deleteFirst {
                        deleteFirstButton
                        keepButton(newFileID: newZimFile.fileID)
                    } else {
                        keepButton(newFileID: newZimFile.fileID)
                        deleteFirstButton
                    }
                }
                Button(LocalString.common_button_cancel, role: .cancel) {}
            } message: {
                Text(choiceMessage(newSize: newZimFile.size))
            }
            .alert(
                LocalString.zim_file_update_delete_first_confirm_title,
                isPresented: $isPresentingDeleteFirstConfirmation
            ) {
                Button(LocalString.zim_file_update_delete_first_confirm_button, role: .destructive) {
                    let oldFileID = zimFile.fileID
                    let newFileID = newZimFile.fileID
                    let newSize = newZimFile.size
                    let allowsCellular = downloadUsingCellular
                    Task {
                        await deleteThenDownload(oldFileID: oldFileID,
                                                 newFileID: newFileID,
                                                 newSize: newSize,
                                                 allowsCellular: allowsCellular)
                    }
                }
                Button(LocalString.common_button_cancel, role: .cancel) {}
            } message: {
                Text(LocalString.zim_file_update_delete_first_confirm_message)
            }
            HStack {
                Text(LocalString.zim_file_update_installed(withArgs: Self.dateFormatter.string(from: zimFile.created)))
                Text(LocalString.zim_file_update_available(
                    withArgs: Self.dateFormatter.string(from: newZimFile.created)
                ))
                Spacer()
                Text(ZimFileCell.sizeFormatter.string(fromByteCount: newZimFile.size))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private func keepButton(newFileID: UUID) -> some View {
        Button(LocalString.zim_file_update_dialog_keep) {
            let oldFileID = zimFile.fileID
            let allowsCellular = downloadUsingCellular
            Task {
                await DownloadService.shared.start(
                    zimFileID: newFileID, allowsCellularAccess: allowsCellular, replacing: oldFileID
                )
            }
        }
        .keyboardShortcut(preselected == .keepUntilDone ? .defaultAction : nil)
    }

    private var deleteFirstButton: some View {
        Button(LocalString.zim_file_update_dialog_delete_first, role: .destructive) {
            isPresentingDeleteFirstConfirmation = true
        }
        .keyboardShortcut(preselected == .deleteFirst ? .defaultAction : nil)
    }

    /// Frees up the space of the current version first, and only downloads the new one if that worked.
    /// When the file could not be removed, the user is told, and we fall back to keeping it,
    /// as long as there is room for the new version next to it.
    private func deleteThenDownload(oldFileID: UUID,
                                    newFileID: UUID,
                                    newSize: Int64,
                                    allowsCellular: Bool) async {
        let oldFilePath = await ZimReplacement.filePath(of: oldFileID)
        guard await ZimReplacement.deleteFileKeepingRecord(oldFileID: oldFileID) else {
            if let oldFilePath {
                DownloadUI.showAlert(.zimFileNotRemoved(path: oldFilePath))
            }
            if let freeSpace = ZimReplacement.freeSpace(), freeSpace >= newSize {
                await DownloadService.shared.start(
                    zimFileID: newFileID, allowsCellularAccess: allowsCellular, replacing: oldFileID
                )
            }
            return
        }
        await DownloadService.shared.start(
            zimFileID: newFileID, allowsCellularAccess: allowsCellular, replacing: oldFileID
        )
    }

    private func choiceMessage(newSize: Int64) -> String {
        let formatter = ZimFileCell.sizeFormatter
        var lines = [
            LocalString.zim_file_update_dialog_new_size(withArgs: formatter.string(fromByteCount: newSize)),
            LocalString.zim_file_update_dialog_current_size(withArgs: formatter.string(fromByteCount: zimFile.size))
        ]
        if let freeSpace {
            lines.append(LocalString.zim_file_update_dialog_free_space(
                withArgs: formatter.string(fromByteCount: freeSpace)
            ))
        } else {
            lines.append(LocalString.zim_file_update_dialog_free_space_unknown)
        }
        if !canDeleteOld {
            lines.append(LocalString.zim_file_update_dialog_cannot_delete_current)
        }
        if !canProceed {
            lines.append(canDeleteOld
                         ? LocalString.zim_file_update_dialog_not_enough_space
                         : LocalString.zim_file_update_dialog_not_enough_space_keep)
            if let folder = DownloadDestination.downloadLocalFolder()?.path(percentEncoded: false) {
                lines.append(LocalString.zim_file_update_dialog_free_up_folder(withArgs: folder))
            }
        }
        return lines.joined(separator: "\n")
    }

    /// The newer version that is being downloaded right now to replace this ZIM file, if any.
    /// The download belongs to the new record, so without this the user would see no sign of it here.
    private func replacementBeingDownloaded() -> ZimFile? {
        // only a downloaded record can be replaced; its file link is optional, so it is safe
        // to read even on a catalog row that the sync has just removed
        guard zimFile.fileURLBookmark != nil else { return nil }
        let oldFileID = zimFile.fileID.uuidString
        guard let newFileID = pendingReplacements.first(where: { $0.value == oldFileID })?.key,
              let newZimFile = zimFile(withID: newFileID),
              newZimFile.downloadTask != nil else {
            return nil
        }
        return newZimFile
    }

    /// The newer, not yet downloaded version of this ZIM file, if the catalog has one
    private func newerVersion() -> ZimFile? {
        guard zimFile.fileURLBookmark != nil, !zimFile.isMissing,
              let newFileID = ZimUpdates.availableUpdate(for: zimFile.fileID, in: updates) else {
            return nil
        }
        return zimFile(withID: newFileID.uuidString)
    }

    private func zimFile(withID fileID: String) -> ZimFile? {
        guard let uuid = UUID(uuidString: fileID) else { return nil }
        let request = ZimFile.fetchRequest(fileID: uuid)
        request.fetchLimit = 1
        return try? Database.shared.viewContext.fetch(request).first
    }

    @MainActor
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
