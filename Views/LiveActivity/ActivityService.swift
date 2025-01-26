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

@available(iOS 16.2, *)
@MainActor
final class ActivityService {
    
    private var cancellables = Set<AnyCancellable>()
    private var activity: Activity<DownloadActivityAttributes>?
    
    init(
        publisher: @MainActor () ->  CurrentValueSubject<[UUID: DownloadState], Never> = { DownloadService.shared.progress.publisher
        }
    ) {
        publisher().sink { [weak self] (state: [UUID : DownloadState]) in
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
        if let activity = try? Activity
            .request(
                attributes: DownloadActivityAttributes(title: "Downloads"),
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
        guard let activity else {
            start(with: state)
            return
        }
        Task {
            await activity.update(
                ActivityContent<DownloadActivityAttributes.ContentState>(
                    state: activityState(from: state),
                    staleDate: nil
                )
            )
        }
    }
    
    private func stop() {
        if let activity {
            let previousState = activity.content.state
            Task {
                await activity.end(
                    ActivityContent(state: completeState(for: previousState), staleDate: nil),
                    dismissalPolicy: .default)
                self.activity = nil
            }
        }
    }
    
    private func activityState(from state: [UUID: DownloadState]) -> DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes.ContentState(
            items: state.map { (key: UUID, download: DownloadState)-> DownloadActivityAttributes.DownloadItem in
            DownloadActivityAttributes.DownloadItem(uuid: key, description: key.uuidString, progress: Double(download.downloaded/download.total))
        })
    }
    
    private func completeState(for previousState: DownloadActivityAttributes.ContentState) -> DownloadActivityAttributes.ContentState {
        DownloadActivityAttributes
            .ContentState(items: previousState.items.map { item in
            DownloadActivityAttributes.DownloadItem(completedFor: item.uuid)
        })
    }
}

#endif
