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
    private let averageDownloadSpeedFromLastSeconds: Double
    private let publisher: @MainActor () -> CurrentValueSubject<[UUID: DownloadState], Never>
    private var isStarted: Bool = false
    private var downloadTimes: [UUID: DownloadTime] = [:]
    
    init(
        publisher: @MainActor @escaping () -> CurrentValueSubject<[UUID: DownloadState], Never> = {
            DownloadService.shared.progress.publisher
        },
        updateFrequency: Double = 10,
        averageDownloadSpeedFromLastSeconds: Double = 30
    ) {
        assert(updateFrequency > 0)
        assert(averageDownloadSpeedFromLastSeconds > 0)
        self.updateFrequency = updateFrequency
        self.averageDownloadSpeedFromLastSeconds = averageDownloadSpeedFromLastSeconds
        self.publisher = publisher
    }
    
    func start() {
        publisher().sink { [weak self] (state: [UUID: DownloadState]) in
            guard let self else { return }
            if state.isEmpty {
                stop()
            } else {
                update(state: state)
            }
        }.store(in: &cancellables)
    }
    
    private func start(with state: [UUID: DownloadState], downloadTimes: [UUID: CFTimeInterval]) {
        Task {
            let activityState = await activityState(from: state, downloadTimes: downloadTimes)
            let content = ActivityContent(
                state: activityState,
                staleDate: nil,
                relevanceScore: 0.0
            )
            if let localActivity = try? Activity
                .request(
                    attributes: DownloadActivityAttributes(),
                    content: content,
                    pushType: nil
                ) {
                activity = localActivity
                for await activityState in localActivity.activityStateUpdates {
                    if [.ended, .dismissed].contains(activityState),
                       localActivity.id == activity?.id {
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
        let downloadTimes: [UUID: CFTimeInterval] = updatedDownloadTimes(from: state)
        guard isStarted else {
            isStarted = true
            start(with: state, downloadTimes: downloadTimes)
            return
        }
        let now = CACurrentMediaTime()
        guard let activity, (now - lastUpdate) > updateFrequency else {
            return
        }
        lastUpdate = now
        Task {
            let activityState = await activityState(from: state, downloadTimes: downloadTimes)
            await activity.update(
                ActivityContent<DownloadActivityAttributes.ContentState>(
                    state: activityState,
                    staleDate: nil
                )
            )
        }
    }
    
    private func updatedDownloadTimes(from states: [UUID: DownloadState]) -> [UUID: CFTimeInterval] {
        // remove the ones we should no longer track
        downloadTimes = downloadTimes.filter({ key, _ in
            states.keys.contains(key)
        })
        
        let now = CACurrentMediaTime()
        for (key, state) in states {
            let downloadTime: DownloadTime = downloadTimes[key] ?? DownloadTime(
                considerLastSeconds: averageDownloadSpeedFromLastSeconds,
                total: state.total
            )
            downloadTime.update(downloaded: state.downloaded, now: now)
            downloadTimes[key] = downloadTime
        }
        return downloadTimes.reduce(into: [:], { partialResult, time in
            let (key, value) = time
            partialResult.updateValue(value.remainingTime(now: now), forKey: key)
        })
    }
    
    private func stop() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
            isStarted = false
            downloadTimes = [:]
        }
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
    
    private func activityState(from state: [UUID: DownloadState], downloadTimes: [UUID: CFTimeInterval]) async -> DownloadActivityAttributes.ContentState {
        var titles: [UUID: String] = [:]
        for key in state.keys {
            titles[key] = await getDownloadTitle(for: key)
        }
        
        return DownloadActivityAttributes.ContentState(
            downloadingTitle: LocalString.download_task_cell_status_downloading,
            items: state.map { (key: UUID, download: DownloadState) -> DownloadActivityAttributes.DownloadItem in
                DownloadActivityAttributes.DownloadItem(
                    uuid: key,
                    description: titles[key] ?? key.uuidString,
                    downloaded: download.downloaded,
                    total: download.total,
                    timeRemaining: downloadTimes[key] ?? 0)
        })
    }
}

#endif
