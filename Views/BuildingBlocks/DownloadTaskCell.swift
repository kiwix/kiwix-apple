/*
65;6800;1c * This file is part of Kiwix for iOS & macOS.
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

import CoreData
import SwiftUI
import Combine

struct DownloadTaskCell: View {
    @State private var isHovering: Bool = false
    @State private var downloadState = DownloadState(downloaded: 0, total: 1, resumeData: nil)

    let downloadTask: DownloadTask
    init(_ downloadTask: DownloadTask) {
        self.downloadTask = downloadTask
    }

    var body: some View {
        let progress: Progress = {
            let p = Progress(totalUnitCount: downloadState.total)
            p.completedUnitCount = downloadState.downloaded
            p.kind = .file
            p.fileTotalCount = 1
            p.fileOperationKind = .downloading
            return p
        }()
        VStack(spacing: 8) {
            if let zimFile = downloadTask.zimFile {
                HStack {
                    Text(zimFile.name).fontWeight(.semibold).foregroundColor(.primary).lineLimit(1)
                    Spacer()
                    Favicon(
                        category: Category(rawValue: zimFile.category) ?? .other,
                        imageData: zimFile.faviconData,
                        imageURL: zimFile.faviconURL
                    ).frame(height: 20)
                }
            } else {
                Text(downloadTask.fileID.uuidString)
            }
            VStack(alignment: .leading, spacing: 4) {
                if downloadTask.error != nil {
                    Text("download_task_cell.status.failed".localized)
                } else if downloadState.resumeData == nil {
                    Text("download_task_cell.status.downloading".localized)
                } else {
                    Text("download_task_cell.status.paused".localized)
                }
                ProgressView(
                    value: Float(downloadState.downloaded),
                    total: Float(downloadState.total)
                )
                Text(progress.localizedAdditionalDescription).animation(.none, value: progress)
            }.font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .modifier(CellBackground(isHovering: isHovering))
        .onHover { self.isHovering = $0 }
        .onReceive(DownloadService.shared.progress.publisher) { states in
            if let state = states[downloadTask.fileID] {
                self.downloadState = state
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
        return zimFile
    }()
    static let downloadTask: DownloadTask = {
        let downloadTask = DownloadTask(context: context)
        downloadTask.zimFile = zimFile
        return downloadTask
    }()

    static var previews: some View {
        DownloadTaskCell(DownloadTaskCell_Previews.downloadTask)
            .preferredColorScheme(.light)
            .padding()
            .frame(width: 300, height: 125)
            .previewLayout(.sizeThatFits)
        DownloadTaskCell(DownloadTaskCell_Previews.downloadTask)
            .preferredColorScheme(.dark)
            .padding()
            .frame(width: 300, height: 125)
            .previewLayout(.sizeThatFits)
    }
}
