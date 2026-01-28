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
import CoreData
@testable import Kiwix

final class TestDatabase: Databasing {
    
    var zimFiles: [ZimFileStruct] = []
    
    func fetchZimFiles() async throws -> [ZimFileStruct] {
        zimFiles
    }
    
    func fetchZimFileIds() async throws -> [UUID] {
        zimFiles.map { $0.fileID }
    }
    
    func fetchZimFileCategoryLanguageData() async throws -> [ZimFileCategoryLanguageData] {
        zimFiles.map {
            ZimFileCategoryLanguageData(category: $0.category, languageCode: $0.languageCode)
        }
    }
    
    func bulkInsert(metadata: [ZimFileMetaStruct]) async throws -> Int {
        let newFileIds = metadata.map { $0.fileID }
        let oldFiles = zimFiles.filter { zimFile in
            newFileIds.contains(zimFile.fileID) == false
        }
        let newFiles = metadata.map { metadata in
            ZimFileStruct(from: metadata)
        }
        zimFiles = oldFiles + newFiles
        return newFiles.count
    }
    
    func bulkDeleteNotDownloadedZims(notIncludedIn: Set<UUID>) async throws -> Int {
        let oldCount = zimFiles.count
        zimFiles = zimFiles.filter { zimFile in
            notIncludedIn.contains(zimFile.fileID) || zimFile.fileURLBookmark != nil
        }
        let newCount = zimFiles.count
        return oldCount - newCount
    }
    
    func update(with changedZimFile: ZimFileStruct) {
        zimFiles = zimFiles.map { zimFile in
            guard zimFile.fileID == changedZimFile.fileID else {
                return zimFile
            }
            return changedZimFile
        }
    }
}

private extension ZimFileStruct {
    /// Based on LibraryOperations configureZimFile
    init(from metadata: ZimFileMetaStruct) {
        self.init(articleCount: metadata.articleCount,
                  category: (Category(rawValue: metadata.category) ?? .other).rawValue,
                  created: metadata.creationDate,
                  downloadURL: metadata.downloadURL,
                  faviconData: metadata.faviconData,
                  faviconURL: metadata.faviconURL,
                  fileDescription: metadata.fileDescription,
                  fileID: metadata.fileID,
                  flavor: metadata.flavor,
                  hasDetails: metadata.hasDetails,
                  hasPictures: metadata.hasPictures,
                  hasVideos: metadata.hasVideos,
                  includedInSearch: true,
                  isMissing: false,
                  languageCode: metadata.languageCodes,
                  mediaCount: metadata.mediaCount,
                  name: metadata.title,
                  persistentID: metadata.groupIdentifier,
                  requiresServiceWorkers: metadata.requiresServiceWorkers,
                  size: metadata.size)
    }
    
}
