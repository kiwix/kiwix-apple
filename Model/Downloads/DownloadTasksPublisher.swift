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
import Combine

@MainActor
final class DownloadTasksPublisher {

    let publisher: CurrentValueSubject<[UUID: DownloadState], Never>
    private var states = [UUID: DownloadState]()

    init() {
        publisher = CurrentValueSubject(states)
        if let jsonData = UserDefaults.standard.object(forKey: "downloadStates") as? Data,
           let storedStates = try? JSONDecoder().decode([UUID: DownloadState].self, from: jsonData) {
            states = storedStates
            publisher.send(states)
        }
    }

    func updateFor(uuid: UUID, downloaded: Int64, total: Int64) {
        if let state = states[uuid] {
            states[uuid] = state.updatedWith(downloaded: downloaded, total: total)
        } else {
            states[uuid] = DownloadState(downloaded: downloaded, total: total, resumeData: nil, isPaused: false)
        }
        publisher.send(states)
        saveState()
    }

    func resetFor(uuid: UUID) {
        states.removeValue(forKey: uuid)
        publisher.send(states)
        saveState()
    }

    func isEmpty() -> Bool {
        states.isEmpty
    }

    func resumeDataFor(uuid: UUID) -> Data? {
        states[uuid]?.resumeData
    }

    func updateFor(uuid: UUID, withResumeData resumeData: Data?, isPaused: Bool) {
        if let state = states[uuid] {
            states[uuid] = state.updatedWith(resumeData: resumeData, isPaused: isPaused)
            publisher.send(states)
            saveState()
        } else {
            assertionFailure("there should be a download task for: \(uuid)")
        }
    }
    
    private func saveState() {
        if let jsonStates = try? JSONEncoder().encode(states) {
            UserDefaults.standard.setValue(jsonStates, forKey: "downloadStates")
        }
    }
}
