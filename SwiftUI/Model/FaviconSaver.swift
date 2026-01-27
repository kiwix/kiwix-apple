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

import CoreData
import Combine
import Foundation
import os

final class FaviconSaver {
    
    static let shared = FaviconSaver()
    private var store: [URL: Data] = [:]
    private let lock = OSAllocatedUnfairLock()
    private let subject = PassthroughSubject<Void, Never>()
    private var cancellable: AnyCancellable!
    
    private init() {
        cancellable = subject
            .debounce(for: .seconds(0.75), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let dictToSave = store
                self.lock.withLock {
                    self.store.removeAll()
                }
                self.bulkSaveToDB(dict: dictToSave)
            }
    }
    
    func saveData(_ data: Data, for url: URL) {
        lock.withLock {
            if store[url] == nil {
                store[url] = data
                subject.send(())
            }
        }
    }
    
    private func bulkSaveToDB(dict: [URL: Data]) {
        Task(priority: .utility) {
            let context = Database.shared.backgroundContext
            await context.perform {
                for (url, data) in dict {
                    let request = NSBatchUpdateRequest(
                        entity: ZimFile.entity(),
                    )
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "faviconURL == %@", url.absoluteString as CVarArg),
                        NSPredicate(format: "faviconData == nil")
                    ])
                    
                    request.propertiesToUpdate = ["faviconData": data]
                    request.includesSubentities = false
                    request.resultType = .updatedObjectsCountResultType
                    _ = try? context.execute(request) as? NSBatchUpdateResult
                }
            }
        }
    }
}
