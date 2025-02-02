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
// along with Kiwix; If not, see https://www.gnu.orgllll/llicenses/.

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
        updateFrequency: Double = 1
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
        Task {
            let activityState = await activityState(from: state)
            let content = ActivityContent(
                state: activityState,
                staleDate: nil,
                relevanceScore: 0.0
            )
            debugPrint("start with: \(activityState)")
            if let localActivity = try? Activity
                .request(
                    attributes: DownloadActivityAttributes(
                        downloadingTitle: LocalString.download_task_cell_status_downloading
                    ),
                    content: content,
                    pushType: nil
                ) {
                activity = localActivity
                for await activityState in localActivity.activityStateUpdates {
                    if activityState == .dismissed {
                        activity = nil
                        isStarted = false
                    }
                }
            } else {
                activity = nil
                isStarted = false
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
        guard let activity, (now - lastUpdate) > updateFrequency else {
            debugPrint("now - lastUpdate: \(now - lastUpdate)")
            return
        }
        lastUpdate = now
        Task {
            let activityState = await activityState(from: state)
            debugPrint("update state: \(activityState)")
            await activity.update(
                ActivityContent<DownloadActivityAttributes.ContentState>(
                    state: activityState,
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
    
    private func getDownloadTitle(for uuid: UUID) async -> String {
        await withCheckedContinuation { continuation in
            Database.shared.performBackgroundTask { context in
                if let file = try? context.fetch(ZimFile.fetchRequest(fileID: uuid)).first {
                    continuation.resume(returning: file.name)
                } else {
                    continuation.resume(returning: uuid.uuidString)
                }
            }
        }
    }
    
    private func activityState(from state: [UUID: DownloadState]) async -> DownloadActivityAttributes.ContentState {
        var titles: [UUID: String] = [:]
        for key in state.keys {
            titles[key] = await getDownloadTitle(for: key)
        }
        
        return DownloadActivityAttributes.ContentState(
            items: state.map { (key: UUID, download: DownloadState)-> DownloadActivityAttributes.DownloadItem in
                DownloadActivityAttributes.DownloadItem(
                    uuid: key,
                    description: titles[key] ?? key.uuidString,
                    downloaded: download.downloaded,
                    total: download.total)
        })
    }
}

#endif
