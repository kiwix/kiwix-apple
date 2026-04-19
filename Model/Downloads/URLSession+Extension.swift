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

// Extensions for look up and filter by zimFileID
// which is stored in the taskDescription

extension URLSessionTask {
    var zimFileID: UUID? {
        guard let taskDescription else { return nil }
        return UUID(uuidString: taskDescription)
    }
    
    func set(zimFileID: UUID) {
        taskDescription = zimFileID.uuidString
    }
}

extension Collection where Element: URLSessionTask {
    func firstBy(zimFileID: UUID) -> URLSessionTask? {
        first(where: { $0.taskDescription == zimFileID.uuidString })
    }
}

// Unified way of getting iOS (downloadTasks) or macOS (dataTasks) from URLSession
extension URLSession {
    
    func getTasks(completion: @escaping @Sendable ([URLSessionTask]) -> Void) {
#if os(iOS)
        getTasksWithCompletionHandler { _, _, downloadTasks in
            completion(downloadTasks)
        }
#else
        getTasksWithCompletionHandler { dataTasks, _, _ in
            completion(dataTasks)
        }
#endif
    }
    
    func taskBy(zimFileID: UUID) async -> URLSessionTask? {
#if os(iOS)
        let (_, _, sessionTasks) = await tasks
#else
        let (sessionTasks, _, _) = await tasks
#endif
        return sessionTasks.firstBy(zimFileID: zimFileID)
    }
    
    func taskBy(zimFileID: UUID, completion: @escaping @Sendable (URLSessionTask?) -> Void) {
        getTasks { tasks in
            completion(tasks.firstBy(zimFileID: zimFileID))
        }
    }
}
