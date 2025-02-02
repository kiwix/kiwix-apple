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
    
    public let downloadingTitle: String
    
    /// - Parameter downloadingTitle: it is localised on the app level
    public init(downloadingTitle: String) {
        self.downloadingTitle = downloadingTitle
    }
    
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
        
        public let items: [DownloadItem]
        
        public var totalProgress: Double {
            progressFor(items: items).fractionCompleted
        }
        
        public var totalSummary: String {
            progressFor(items: items).localizedAdditionalDescription
        }
        
        public init(items: [DownloadItem]) {
            self.items = items
        }
    }

    public struct DownloadItem: Codable & Hashable {
        public let uuid: UUID
        public let description: String
        public let downloaded: Int64
        public let total: Int64
        public var progress: Double {
            progressFor(items: [self]).fractionCompleted
        }
        public var progressDescription: String {
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
