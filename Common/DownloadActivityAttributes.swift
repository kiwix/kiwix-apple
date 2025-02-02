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
#if os(iOS)

import ActivityKit

public struct DownloadActivityAttributes: ActivityAttributes {
    
    private static func progressFor(items: [DownloadItem]) -> Progress {
        let sumOfTotal = items.reduce(0) { result, item in
            result + item.total
        }
        let sumOfDownloaded = items.reduce(0) { result, item in
            result + item.downloaded
        }
        let prog = Progress(totalUnitCount: sumOfTotal)
        prog.completedUnitCount = sumOfDownloaded
        prog.kind = .file
        prog.fileTotalCount = items.count
        prog.fileOperationKind = .downloading
        return prog
    }
    
    public struct ContentState: Codable & Hashable {
        private let items: [DownloadItem]
        private let downloadingTitle: String
        
        /// - Parameter downloadingTitle: it is localised on the app level
        /// - Parameter items: list of download items and their current state
        public init(downloadingTitle: String, items: [DownloadItem]) {
            self.downloadingTitle = downloadingTitle
            self.items = items
        }
        
        public var title: String {
            guard let first = items.first, items.count == 1 else {
                return downloadingTitle
            }
            return first.description
        }
        
        public var progress: Double {
            progressFor(items: items).fractionCompleted
        }
        
        public var progressDescription: String {
            progressFor(items: items).localizedAdditionalDescription
        }
    }

    public struct DownloadItem: Codable & Hashable {
        let uuid: UUID
        let description: String
        let downloaded: Int64
        let total: Int64
        var progress: Double {
            progressFor(items: [self]).fractionCompleted
        }
        var progressDescription: String {
            progressFor(items: [self]).localizedAdditionalDescription
        }
        
        public init(uuid: UUID, description: String, downloaded: Int64, total: Int64) {
            self.uuid = uuid
            self.description = description
            self.downloaded = downloaded
            self.total = total
        }
    }
}
#endif
