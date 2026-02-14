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
    
    struct DownloadTaskDetail: View {
        @ObservedObject var downloadZimFile: ZimFile
        @EnvironmentObject var selection: SelectedZimFileViewModel
        @State private var downloadState = DownloadState.empty()
        @StateObject private var networkState = DownloadService.shared.networkState
        @State private var downloadNetworkState: DownloadTaskNetworkState = .online
        
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
                } else {
                    // Action button
                    if downloadState.resumeData == nil {
                        Action(title: LocalString.zim_file_download_task_action_pause) {
                            DownloadService.shared.pause(zimFileID: downloadZimFile.fileID)
                        }.disabled(downloadNetworkState != .online) // make sure cannot be paused mid-state
                    } else {
                        Action(title: LocalString.zim_file_download_task_action_resume) {
                            DownloadService.shared.resume(zimFileID: downloadZimFile.fileID)
                        }.disabled(downloadNetworkState != .online)
                    }
                    
                    switch downloadNetworkState {
                    case .offline:
                        Attribute(title: LocalString.download_task_cell_status_paused_device_offline, detail: detail)
                    case .waitingForWifi:
                        Attribute(title: LocalString.download_task_cell_status_paused_waiting_for_wifi, detail: detail)
                    case .online:
                        if downloadState.resumeData == nil {
                            Attribute(title: LocalString.zim_file_download_task_action_downloading, detail: detail)
                        } else {
                            // genuinely paused by the user
                            Attribute(title: LocalString.download_task_cell_status_paused, detail: detail)
                        }
                    }
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
            .onChange(of: networkState.onlineState, { _, newState in
                Task {
                    await updateWith(onlineState: newState)
                }
            })
            .task {
                networkState.startMonitoring()
                await updateWith(onlineState: networkState.onlineState)
            }
        }
        
        @MainActor
        private func updateWith(onlineState: OnlineState) async {
            let zimFileID = downloadZimFile.fileID
            guard let allowsCellular = await DownloadService.shared.allowsCellularAccessFor(zimFileID: zimFileID) else {
                return
            }
            let newDowloadNetworkState = DownloadTaskNetworkState(onlineState: onlineState,
                                                                  downloadAllowsCellular: allowsCellular)
            if newDowloadNetworkState != downloadNetworkState {
                downloadNetworkState = newDowloadNetworkState
            }
        }
        
        private var detail: String {
            #if os(macOS)
            if networkState.onlineState == .online {
                if let percent = percent {
                    return "\(size) - \(percent)"
                } else {
                    return size
                }
            } else {
                if let percent = percent {
                    return percent // the offline message has to fit
                } else {
                    return size
                }
            }
            #else
                if let percent = percent {
                    return "\(size) - \(percent)"
                } else {
                    return size
                }
            #endif
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
