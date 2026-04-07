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

extension ZimFileDetail {
    static let downloadWarningThreshold: Int64 = 1_000_000_000

    var downloadAction: some View {
        Action(title: LocalString.zim_file_action_download_title) {
            Task {
                await prepareDownload()
            }
        }.alert(isPresented: $isPresentingDownloadAlert) {
            Alert(
                title: Text(LocalString.zim_file_action_download_warning_title),
                message: Text(downloadWarningMessage),
                primaryButton: .default(Text(LocalString.zim_file_action_download_button_anyway)) {
                    startConfirmedDownload()
                },
                secondaryButton: .cancel {
                    pendingDownloadAvailableCapacity = nil
                    #if os(macOS)
                    pendingDownloadFolder = nil
                    #endif
                }
            )
        }
        #if os(macOS)
        .buttonStyle(.borderedProminent)
        #endif
    }

    var freeSpace: Int64? {
        guard let documentDirectory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first else {
            return nil
        }
        return DownloadDestination.availableCapacity(in: documentDirectory)
    }

    private var downloadWarningMessage: String {
        if let freeSpace = pendingDownloadAvailableCapacity, zimFile.size > freeSpace {
            return LocalString.zim_file_action_download_warning_message
        }
        return LocalString.zim_file_action_download_warning_message1
    }

    func prepareDownload() async {
        #if os(macOS)
        let selector = MacDownloadLocationSelector()
        guard let folder = await selector.selectFolder(
            message: LocalString.download_settings_prompt_message
        ) else {
            return
        }
        let availableCapacity = DownloadDestination.availableCapacity(in: folder)
        pendingDownloadFolder = folder
        pendingDownloadAvailableCapacity = availableCapacity
        if let availableCapacity,
           zimFile.size >= availableCapacity - Self.downloadWarningThreshold {
            isPresentingDownloadAlert = true
            return
        }
        startDownload(to: folder)
        #else
        pendingDownloadAvailableCapacity = freeSpace
        if let freeSpace,
           zimFile.size >= freeSpace - Self.downloadWarningThreshold {
            isPresentingDownloadAlert = true
            return
        }
        startDownload()
        #endif
    }

    func startConfirmedDownload() {
        #if os(macOS)
        startDownload(to: pendingDownloadFolder)
        pendingDownloadFolder = nil
        #else
        startDownload()
        #endif
    }

    func startDownload(to folder: URL? = nil) {
        pendingDownloadAvailableCapacity = nil
        let fileID = zimFile.fileID
        Task {
            await DownloadService.shared.start(
                zimFileID: fileID,
                allowsCellularAccess: downloadUsingCellular,
                destinationFolder: folder
            )
        }
    }
}
