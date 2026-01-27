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

/// Sendable Struct version of ZimFileMetaData
struct ZimFileMetaStruct: Sendable {
    let fileID: UUID
    let groupIdentifier: String
    let title: String
    let fileDescription: String
    let languageCodes: String
    let category: String
    let creationDate: Date
    let size: Int64
    let articleCount: Int64
    let mediaCount: Int64
    let creator: String
    let publisher: String
    
    // nullable attributes
    let downloadURL: URL?
    let faviconURL: URL?
    let faviconData: Data?
    let flavor: String?
    
    // assigned attributes
    let hasDetails: Bool
    let hasPictures: Bool
    let hasVideos: Bool
    let requiresServiceWorkers: Bool
}
