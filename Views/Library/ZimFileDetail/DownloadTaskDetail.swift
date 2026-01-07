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

import Defaults
import SwiftUI

extension ZimFileDetail {
    
    struct DownloadTaskDetail: View {
        @Default(.downloadUsingCellular) private var downloadUsingCellular
        @ObservedObject var downloadZimFile: ZimFile
        @EnvironmentObject var selection: SelectedZimFileViewModel
        @State private var downloadState = DownloadState.empty()
        @StateObject private var networkState = DownloadService.shared.networkState
        
        var body: some View {
            Group {
                Action(title: LocalString.zim_file_download_task_action_title_cancel, isDestructive: true) {
                    DownloadService.shared.cancel(zimFileID: downloadZimFile.fileID)
                    selection.reset()
                }
                if let error = downloadZimFile.downloadTask?.error {
                    if downloadState.resumeData != nil {
                        Action(title: LocalString.zim_file_download_task_action_try_recover) {
                            DownloadService.shared.resume(
                                zimFileID: downloadZimFile.fileID,
                                allowsCellularAccess: downloadUsingCellular
                            )
                        }
                    }
                    Attribute(title: LocalString.zim_file_download_task_action_failed, detail: detail)
                    Text(error)
                } else if !downloadState.isPaused {
                    Action(title: LocalString.zim_file_download_task_action_pause) {
                        DownloadService.shared.pause(zimFileID: downloadZimFile.fileID)
                    }
                    if networkState.isOnline {
                        Attribute(title: LocalString.zim_file_download_task_action_downloading, detail: detail)
                    } else {
                        HStack {
                            Label(LocalString.zim_file_download_task_status_offline, systemImage: "wifi.slash")
                                .foregroundStyle(.orange)
                            Spacer()
                            Text(detail).foregroundColor(.secondary)
                        }
                    }
                } else {
                    Action(title: LocalString.zim_file_download_task_action_resume) {
                        DownloadService.shared.resume(
                            zimFileID: downloadZimFile.fileID,
                            allowsCellularAccess: downloadUsingCellular
                        )
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
            .task {
                networkState.startMonitoring()
            }
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
}
