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

final class TestContext: DBObjectContext {
    
    private let objectContext = NSManagedObjectContext(.privateQueue)
    
    var zimFiles: [ZimFile] = []
    
    func fetchZimFiles() throws -> [ZimFile] {
        zimFiles
    }
    
    func bulkInsert(handler: @escaping (ZimFile) -> Bool) throws -> Int {
        var count = 0
        var zimFile = ZimFile(context: objectContext)
        while handler(zimFile) == false {
            zimFiles.append(zimFile)
            zimFile = ZimFile(context: objectContext)
            count += 1
        }
        return count
    }
    
    func bulkDeleteNotDownloadedZims(notIncludedIn: Set<UUID>) throws -> Int {
        let oldCount = zimFiles.count
        zimFiles = zimFiles.filter { zimFile in
            notIncludedIn.contains(zimFile.fileID) || zimFile.fileURLBookmark != nil
        }
        let newCount = zimFiles.count
        return oldCount - newCount
    }
    
}

final class TestDatabase: Databasing {
    
    var context: DBObjectContext = TestContext()
    
    func backgroundTask(_ block: @escaping (any DBObjectContext) -> Void) {
        block(context)
    }
}
