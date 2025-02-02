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

import Combine
import ActivityKit
import QuartzCore

@MainActor
final class ActivityService {
    
    private var cancellables = Set<AnyCancellable>()
    private var activity: Activity<DownloadActivityAttributes>?
    private var lastUpdate = CACurrentMediaTime()
    private let updateFrequency: Double
    private let publisher: CurrentValueSubject<[UUID: DownloadState], Never>
    private var isStarted: Bool = false
    
    init(
        publisher: @MainActor () ->  CurrentValueSubject<[UUID: DownloadState], Never> = { DownloadService.shared.progress.publisher
        },
        updateFrequency: Double = 5
    ) {
        assert(updateFrequency > 0)
        self.updateFrequency = updateFrequency
        self.publisher = publisher()
    }
    
    func start() {
        publisher.sink { [weak self] (state: [UUID : DownloadState]) in
            guard let self else { return }
            if state.isEmpty {
                stop()
            } else {
                update(state: state)
            }
        }.store(in: &cancellables)
    }
    
    private func start(with state: [UUID: DownloadState]) {
        let content = ActivityContent(
            state: activityState(from: state),
            staleDate: nil,
            relevanceScore: 0.0
        )
        debugPrint("start with: \(state)")
        if let activity = try? Activity
            .request(
                attributes: DownloadActivityAttributes(
                    downloadingTitle: LocalString.download_task_cell_status_downloading
                ),
                content: content,
                pushType: nil
            ) {
            Task {
                for await activityState in activity.activityStateUpdates {
                    if activityState == .dismissed {
                        self.activity = nil
                    }
                }
            }
        }
    }
    
    private func update(state: [UUID: DownloadState]) {
        guard isStarted else {
            isStarted = true
            start(with: state)
            return
        }
        let now = CACurrentMediaTime()
        guard (now - lastUpdate) > updateFrequency else {
            debugPrint("now - lastUpdate: \(now - lastUpdate)")
            return
        }
        debugPrint("update state: \(state)")
        lastUpdate = now
        Task {
            await activity?.update(
                ActivityContent<DownloadActivityAttributes.ContentState>(
                    state: activityState(from: state),
                    staleDate: nil
                )
            )
        }
    }
    
    private func stop() {
        debugPrint("stop")
        self.activity = nil
        self.isStarted = false
    }
    
    private func activityState(from state: [UUID: DownloadState]) -> DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(
            items: state.map { (key: UUID, download: DownloadState)-> DownloadActivityAttributes.DownloadItem in
                DownloadActivityAttributes.DownloadItem(
                    uuid: key,
                    description: String(key.uuidString.prefix(3)),
                    downloaded: download.downloaded,
                    total: download.total)
        })
    }
}

#endif
