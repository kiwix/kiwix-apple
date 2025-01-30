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
    
    public let title: String
    
    public init(title: String) {
        self.title = title
    }
    
    public struct ContentState: Codable & Hashable {
        public let items: [DownloadItem]
        public var totalProgress: Double {
            let sum = items.reduce(Double(0.0), { partialResult, item in
                partialResult + item.progress
            })
            return sum / Double(items.count)
        }
        
        public init(items: [DownloadItem]) {
            self.items = items
        }
    }

    public struct DownloadItem: Codable & Hashable {
        public let uuid: UUID
        public let description: String
        public let progress: Double
        
        public init(uuid: UUID, description: String, progress: Double) {
            self.uuid = uuid
            self.description = description
            self.progress = progress
        }
        
        public init(completedFor uuid: UUID) {
            self.uuid = uuid
            self.progress = 1.0
            self.description = "Completed!" //TODO: update
        }
    }
}
#endif
