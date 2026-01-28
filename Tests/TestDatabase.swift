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
    
    //FIXME: this should be a struct based on ZimFile not the metadata!!!
    // revert the test cases and do it again !
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
    
    func bulkInsert(metadata: [ZimFileStruct]) async throws -> Int {
        zimFiles.append(contentsOf: metadata)
        return metadata.count
    }
    
    func bulkDeleteNotDownloadedZims(notIncludedIn: Set<UUID>) async throws -> Int {
        let oldCount = zimFiles.count
        zimFiles = zimFiles.filter { zimFile in
            notIncludedIn.contains(zimFile.fileID)
        }
        let newCount = zimFiles.count
        return oldCount - newCount
    }
}
