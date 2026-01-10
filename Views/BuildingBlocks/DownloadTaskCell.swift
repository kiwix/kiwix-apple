/*
 * This file is part of Kiwix for iOS & macOS.
 *
 * Kiwix is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * Kiwix is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Kiwix; If not, see https://www.gnu.org/licenses/.
*/

import Combine
import CoreData
import SwiftUI
import Combine

struct DownloadTaskCell: View {
    @EnvironmentObject var selection: SelectedZimFileViewModel
    @State private var isHovering: Bool = false
    @State private var downloadState = DownloadUIState.empty()
    @StateObject private var networkState = DownloadService.shared.networkState
    
    let downloadZimFile: ZimFile
    init(_ downloadZimFile: ZimFile) {
        self.downloadZimFile = downloadZimFile
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(downloadZimFile.name).fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                Spacer()
                Favicon(
                    category: Category(rawValue: downloadZimFile.category) ?? .other,
                    imageData: downloadZimFile.faviconData,
                    imageURL: downloadZimFile.faviconURL
                ).frame(height: 20)
            }
            VStack(alignment: .leading, spacing: 4) {
                if downloadZimFile.downloadTask?.error != nil {
                    Text(LocalString.download_task_cell_status_failed)
                } else {
                    switch downloadState.state {
                    case .resumed:
                        Text(LocalString.download_task_cell_status_downloading)
                    case .paused(isOnline: true):
                        Text(LocalString.download_task_cell_status_paused)
                    case .paused(isOnline: false):
                        Text(LocalString.download_task_cell_status_paused_device_offline)
                    }
                    ProgressView(
                        value: Float(downloadState.progress.completedUnitCount),
                        total: Float(downloadState.progress.totalUnitCount)
                    )
                    Text(downloadState.progress.localizedAdditionalDescription).animation(.none, value: downloadState.progress)
                }
            }.font(.caption).foregroundColor(.secondary)
                .padding()
                .background(
                    CellBackground.colorFor(
                        isHovering: isHovering,
                        isSelected: selection.isSelected(downloadZimFile)
                    )
                )
                .clipShape(CellBackground.clipShapeRectangle)
                .onHover { self.isHovering = $0 }
                .onReceive(
                    Publishers.CombineLatest(
                        DownloadService.shared.progress.publisher,
                        networkState.$isOnline
                    )) { values in
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
    }
}

struct DownloadTaskCell_Previews: PreviewProvider {
    static let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    static let zimFile: ZimFile = {
        let zimFile = ZimFile(context: context)
        zimFile.articleCount = 100
        zimFile.category = "wikipedia"
        zimFile.created = Date()
        zimFile.fileID = UUID()
        zimFile.flavor = "mini"
        zimFile.languageCode = "en"
        zimFile.mediaCount = 100
        zimFile.name = "Wikipedia"
        zimFile.persistentID = ""
        zimFile.size = 1000000000
        zimFile.downloadTask = downloadTask
        return zimFile
    }()
    static let downloadTask: DownloadTask = {
        let downloadTask = DownloadTask(context: context)
        downloadTask.zimFile = zimFile
        return downloadTask
    }()

    static var previews: some View {
        DownloadTaskCell(zimFile)
            .preferredColorScheme(.light)
            .padding()
            .frame(width: 300, height: 125)
            .previewLayout(.sizeThatFits)
        DownloadTaskCell(zimFile)
            .preferredColorScheme(.dark)
            .padding()
            .frame(width: 300, height: 125)
            .previewLayout(.sizeThatFits)
    }
}
