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

import Foundation

/// Sendable variant of ZimFile
struct ZimFileStruct {
    let articleCount: Int64
    let category: String
    let created: Date
    let downloadURL: URL?
    let faviconData: Data?
    let faviconURL: URL?
    let fileDescription: String
    let fileID: UUID
    ///  System file URL, if not nil, it means it's downloaded
    var fileURLBookmark: Data?
    let flavor: String?
    let hasDetails: Bool
    let hasPictures: Bool
    let hasVideos: Bool
    let includedInSearch: Bool
    let isMissing: Bool
    var isIntegrityChecked: Bool?
    let languageCode: String
    let mediaCount: Int64
    let name: String
    let persistentID: String
    let requiresServiceWorkers: Bool
    let size: Int64
}
