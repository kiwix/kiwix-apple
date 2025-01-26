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

struct DownloadActivityAttributes: ActivityAttributes {
    
    let title: String
    
    struct ContentState: Codable & Hashable {
        let items: [DownloadItem]
        var totalProgress: Double {
            let sum = items.reduce(Double(0.0), { partialResult, item in
                partialResult + item.progress
            })
            return sum / Double(items.count)
        }
    }

    struct DownloadItem: Codable & Hashable {
        let description: String
        let progress: Double
    }
}
#endif
