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
import Defaults
import SwiftUI

extension ZimFileDetail {
    
    struct DownloadTaskDetail: View {
        @Default(.downloadUsingCellular) private var downloadUsingCellular
        @ObservedObject var downloadZimFile: ZimFile
        @EnvironmentObject var selection: SelectedZimFileViewModel
        @State private var downloadState = DownloadUIState.empty()
        @StateObject private var networkState = DownloadService.shared.networkState
        
        var body: some View {
            Group {
                Action(title: LocalString.zim_file_download_task_action_title_cancel, isDestructive: true) {
                    DownloadService.shared.cancel(zimFileID: downloadZimFile.fileID)
                    selection.reset()
                }
                if let error = downloadZimFile.downloadTask?.error {
                    if downloadState.hasResumeData {
                        Action(title: LocalString.zim_file_download_task_action_try_recover) {
                            DownloadService.shared.resume(
                                zimFileID: downloadZimFile.fileID,
                                allowsCellularAccess: downloadUsingCellular
                            )
                        }
                    }
                    Attribute(title: LocalString.zim_file_download_task_action_failed, detail: detail)
                    Text(error)
                } else {
                    switch downloadState.state {
                    case .resumed:
                        Action(title: LocalString.zim_file_download_task_action_pause) {
                            DownloadService.shared.pause(zimFileID: downloadZimFile.fileID)
                        }
                        Attribute(title: LocalString.zim_file_download_task_action_downloading, detail: detail)
                    case let .paused(isOnline):
                        Action(title: LocalString.zim_file_download_task_action_resume) {
                            DownloadService.shared.resume(
                                zimFileID: downloadZimFile.fileID,
                                allowsCellularAccess: downloadUsingCellular
                            )
                        }.disabled(!isOnline)
                        let pauseTitle: String = if isOnline {
                            LocalString.download_task_cell_status_paused
                        } else {
                            LocalString.download_task_cell_status_paused_device_offline
                        }
                        Attribute(title: pauseTitle, detail: detail)
                    }
                }
            }.onReceive(
                Publishers.CombineLatest(
                    DownloadService.shared.progress.publisher,
                    networkState.$isOnline
                )
            ) { [self] values in
                let states = values.0
                let isOnline = values.1
                if !states.isEmpty, let state = states[downloadZimFile.fileID] {
                    self.downloadState = DownloadUIState(downloadState: state, isOnline: isOnline)
                }
            }
            .task {
                networkState.startMonitoring()
            }
        }
        
        private var detail: String {
            #if os(macOS)
            if let percent = downloadState.percent {
                if networkState.isOnline {
                    return "\(downloadState.size) - \(percent)"
                } else {
                    return percent
                }
            } else {
                return downloadState.size
            }
            #else
                if let percent = downloadState.percent {
                    return "\(downloadState.size) - \(percent)"
                } else {
                    return downloadState.size
                }
            #endif
        }
    }
}
