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

// swiftlint:disable file_length

#if os(macOS)
import Foundation
import Combine
import AppKit

// MARK: - DownloadTaskInfo

/// Lightweight, Sendable struct describing a download task's state.
struct DownloadTaskInfo: Sendable {
    let zimFileID: UUID
    let downloadURL: URL
    let destinationURL: URL
    let expectedTotalBytes: Int64
    var isPaused: Bool = false
    var error: DirectWriteDownloadError? = nil
    var securityScopedAccess: Bool = false
    var retryCount: Int = 0
    var lastLoggedPercentage: Int = -1
}

// MARK: - DirectWriteDownloadService

/// Service for downloading files directly to a custom directory on macOS.
///
/// Architecture (mirrors upstream DownloadService / DownloadSessionDelegate split):
/// - `DirectWriteSessionDelegate`: URLSessionDataDelegate handling the data flow
///   - `DownloadDataBuffer` actor: buffers incoming data (hot path)
///   - `DownloadFileWriter` actor: serializes all disk I/O
/// - This class: download lifecycle (start/pause/resume/cancel), state, timers, sleep prevention
@MainActor
final class DirectWriteDownloadService: NSObject, ObservableObject {

    static let shared = DirectWriteDownloadService()

    @Published private(set) var activeDownloads: [UUID: DownloadTaskInfo] = [:]
    private var sessionTasks: [UUID: URLSessionDataTask] = [:]

    let sessionDelegate: DirectWriteSessionDelegate

    private let writeBufferSize = 16 * 1024 * 1024
    private let stateAutoSaveInterval: TimeInterval = 30
    private let maxRetryAttempts = 5
    private let retryDelay: TimeInterval = 3.0

    private var urlSession: URLSession!
    private var sleepAssertion: NSObjectProtocol?
    private var progressTimer: Timer?
    private var autoSaveTimer: Timer?
    private var wakeObserver: NSObjectProtocol?

    // MARK: - Initialization

    private override init() {
        let buffer = DownloadDataBuffer(flushThreshold: writeBufferSize)
        let fileWriter = DownloadFileWriter()
        self.sessionDelegate = DirectWriteSessionDelegate(
            buffer: buffer, fileWriter: fileWriter
        )
        super.init()

        sessionDelegate.onFlush = { [weak self] zimFileID, bytesWritten in
            self?.didFlush(zimFileID: zimFileID, bytesWritten: bytesWritten)
        }
        sessionDelegate.onCompletion = { [weak self] zimFileID, error in
            self?.handleCompletion(zimFileID: zimFileID, error: error)
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 0
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = true

        let sessionQueue = OperationQueue()
        sessionQueue.name = "org.kiwix.directwrite.session"
        sessionQueue.maxConcurrentOperationCount = 1

        self.urlSession = URLSession(
            configuration: configuration, delegate: sessionDelegate, delegateQueue: sessionQueue
        )

        setupWakeObserver()
        Task { restoreInterruptedDownloads() }
    }

    // MARK: - Wake Observer

    private func setupWakeObserver() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemWake()
            }
        }
    }

    private func handleSystemWake() {
        Log.DownloadService.info("System woke from sleep, checking downloads...")
        for (zimFileID, info) in activeDownloads where info.error != nil && !info.isPaused {
            Log.DownloadService.info(
                "Auto-resuming download for \(zimFileID.uuidString, privacy: .public)"
            )
            activeDownloads[zimFileID]?.retryCount = 0
            activeDownloads[zimFileID]?.error = nil
            Task { await resume(zimFileID: zimFileID) }
        }
    }

    // MARK: - Public Methods

    func start(
        zimFileID: UUID, downloadURL: URL, expectedSize: Int64, allowsCellularAccess: Bool = true
    ) async {
        guard activeDownloads[zimFileID] == nil else {
            Log.DownloadService.warning(
                "Download already in progress for \(zimFileID.uuidString, privacy: .public)"
            )
            return
        }

        guard let directory = DownloadDestination.effectiveDownloadFolder() else {
            Log.DownloadService.error("Cannot determine download directory")
            return
        }

        var needsSecurityScope = false
        if let customDir = DownloadDestination.customDownloadDirectory() {
            needsSecurityScope = customDir.startAccessingSecurityScopedResource()
        }

        let destinationURL = directory.appendingPathComponent(downloadURL.lastPathComponent)
        let validation = DownloadDestination.validateDestination(
            directory: directory, requiredBytes: expectedSize
        )

        switch validation {
        case .valid:
            break
        case .notAccessible, .notWritable:
            Log.DownloadService.error(
                "Directory not accessible: \(directory.path, privacy: .public)"
            )
            showError(.destinationNotAccessible(path: directory.path), for: zimFileID)
            if needsSecurityScope { directory.stopAccessingSecurityScopedResource() }
            return
        case .insufficientSpace(let required, let available):
            Log.DownloadService.error("Insufficient disk space")
            showError(
                .insufficientDiskSpace(required: required, available: available), for: zimFileID
            )
            if needsSecurityScope { directory.stopAccessingSecurityScopedResource() }
            return
        }

        var resumeOffset: Int64 = 0
        if let state = DirectWriteDownloadState.load(for: zimFileID),
           state.validatePartialFile() {
            resumeOffset = state.bytesWritten
            Log.DownloadService.info("Resuming download from byte \(resumeOffset)")
        }

        do {
            try await sessionDelegate.fileWriter.prepare(
                zimFileID: zimFileID, url: destinationURL, offset: resumeOffset
            )
        } catch {
            Log.DownloadService.error(
                "Failed to prepare file: \(error.localizedDescription, privacy: .public)"
            )
            if needsSecurityScope { directory.stopAccessingSecurityScopedResource() }
            return
        }

        var info = DownloadTaskInfo(
            zimFileID: zimFileID,
            downloadURL: downloadURL,
            destinationURL: destinationURL,
            expectedTotalBytes: expectedSize
        )
        info.securityScopedAccess = needsSecurityScope
        activeDownloads[zimFileID] = info

        startURLSessionTask(zimFileID: zimFileID, url: downloadURL, fromOffset: resumeOffset)

        DirectWriteDownloadState(
            zimFileID: zimFileID,
            downloadURL: downloadURL,
            destinationURL: destinationURL,
            expectedTotalBytes: expectedSize
        ).withBytesWritten(resumeOffset).save()

        DownloadService.shared.progress.updateFor(
            uuid: zimFileID, downloaded: resumeOffset, total: expectedSize
        )

        let fileID = zimFileID.uuidString
        let destPath = destinationURL.path
        Log.DownloadService.info(
            "Started direct-write download for \(fileID, privacy: .public) to \(destPath, privacy: .public)"
        )

        if expectedSize > 0 {
            let sizeStr = ByteCountFormatter.string(
                fromByteCount: expectedSize, countStyle: .file
            )
            Log.DownloadService.info(
                "Download progress: 0% (Zero KB / \(sizeStr))"
            )
            activeDownloads[zimFileID]?.lastLoggedPercentage = 0
        }
    }

    func pause(zimFileID: UUID) {
        guard var info = activeDownloads[zimFileID], !info.isPaused else { return }

        info.isPaused = true
        activeDownloads[zimFileID] = info

        let sessionTaskID = sessionTasks[zimFileID]?.taskIdentifier ?? -1
        sessionTasks[zimFileID]?.cancel()
        sessionTasks.removeValue(forKey: zimFileID)

        Task {
            let remaining = await sessionDelegate.buffer.drain(for: sessionTaskID)
            if !remaining.isEmpty {
                try? await sessionDelegate.fileWriter.write(remaining, for: zimFileID)
            }
            await sessionDelegate.fileWriter.close(zimFileID: zimFileID)

            self.saveState(for: zimFileID)
            let placeholderResumeData = Data([0x01])
            DownloadService.shared.progress.updateFor(
                uuid: zimFileID, withResumeData: placeholderResumeData
            )
            Log.DownloadService.info(
                "Paused download for \(zimFileID.uuidString, privacy: .public)"
            )
            self.updateSleepPrevention()
        }
    }

    func resume(zimFileID: UUID) async {
        guard var info = activeDownloads[zimFileID],
              info.isPaused || info.error != nil else { return }

        info.isPaused = false
        info.error = nil
        activeDownloads[zimFileID] = info

        // After app restart, fileWriter has no state — fall back to saved state
        var currentOffset = await sessionDelegate.fileWriter.getBytesWritten(for: zimFileID)
        if currentOffset == 0, let savedState = DirectWriteDownloadState.load(for: zimFileID),
           savedState.validatePartialFile() {
            currentOffset = savedState.bytesWritten
        }

        DownloadService.shared.progress.updateFor(uuid: zimFileID, withResumeData: nil)
        DownloadService.shared.progress.updateFor(
            uuid: zimFileID, downloaded: currentOffset, total: info.expectedTotalBytes
        )

        if !info.securityScopedAccess {
            if let resolvedDir = DownloadDestination.customDownloadDirectory() {
                activeDownloads[zimFileID]?.securityScopedAccess =
                    resolvedDir.startAccessingSecurityScopedResource()
            }
        }

        do {
            try await sessionDelegate.fileWriter.prepare(
                zimFileID: zimFileID, url: info.destinationURL, offset: currentOffset
            )
        } catch {
            Log.DownloadService.error(
                "Failed to reopen file: \(error.localizedDescription, privacy: .public)"
            )
            activeDownloads[zimFileID]?.error = .cannotCreateFile(
                path: info.destinationURL.path, underlyingError: error
            )
            return
        }

        startURLSessionTask(
            zimFileID: zimFileID, url: info.downloadURL, fromOffset: currentOffset
        )
        Log.DownloadService.info(
            "Resumed download for \(zimFileID.uuidString, privacy: .public) from byte \(currentOffset)"
        )
    }

    func cancel(zimFileID: UUID) {
        guard let info = activeDownloads[zimFileID] else { return }

        let sessionTaskID = sessionTasks[zimFileID]?.taskIdentifier ?? -1
        sessionTasks[zimFileID]?.cancel()
        sessionTasks.removeValue(forKey: zimFileID)

        Task {
            await sessionDelegate.buffer.remove(for: sessionTaskID)
            await sessionDelegate.fileWriter.close(zimFileID: zimFileID)
            await sessionDelegate.fileWriter.remove(zimFileID: zimFileID)

            try? FileManager.default.removeItem(at: info.destinationURL)

            if info.securityScopedAccess {
                info.destinationURL.deletingLastPathComponent()
                    .stopAccessingSecurityScopedResource()
            }
            DirectWriteDownloadState.remove(for: zimFileID)
            self.activeDownloads.removeValue(forKey: zimFileID)
            Log.DownloadService.info(
                "Cancelled download for \(zimFileID.uuidString, privacy: .public)"
            )
            self.updateSleepPrevention()
        }
    }

    // MARK: - Delegate Callbacks

    private func didFlush(zimFileID: UUID, bytesWritten: Int64) {
        guard var info = activeDownloads[zimFileID] else { return }

        DownloadService.shared.progress.updateFor(
            uuid: zimFileID, downloaded: bytesWritten, total: info.expectedTotalBytes
        )

        if info.expectedTotalBytes > 0 {
            let percentage = Int(bytesWritten * 100 / info.expectedTotalBytes)
            let milestone = percentage / 10 * 10
            if milestone > info.lastLoggedPercentage {
                info.lastLoggedPercentage = milestone
                activeDownloads[zimFileID] = info
                let writtenStr = ByteCountFormatter.string(
                    fromByteCount: bytesWritten, countStyle: .file
                )
                let totalStr = ByteCountFormatter.string(
                    fromByteCount: info.expectedTotalBytes, countStyle: .file
                )
                Log.DownloadService.info(
                    "Download progress: \(milestone)% (\(writtenStr) / \(totalStr))"
                )
            }
        }

        saveState(for: zimFileID)
    }

    private func handleCompletion(zimFileID: UUID, error: (any Error)?) {
        guard let info = activeDownloads[zimFileID] else { return }
        saveState(for: zimFileID)

        if let error = error {
            let nsError = error as NSError

            if nsError.code == NSURLErrorCancelled && info.isPaused {
                Log.DownloadService.info(
                    "Download paused for \(zimFileID.uuidString, privacy: .public)"
                )
                return
            }

            let fileID = zimFileID.uuidString
            let errorDesc = error.localizedDescription
            Log.DownloadService.error(
                "Download failed for \(fileID, privacy: .public): \(errorDesc, privacy: .public)"
            )

            let recoverableCodes = [
                NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet,
                NSURLErrorTimedOut, NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost
            ]
            if recoverableCodes.contains(nsError.code) {
                scheduleRetry(for: zimFileID)
                return
            }

            activeDownloads[zimFileID]?.isPaused = true
            activeDownloads[zimFileID]?.error = .writeError(
                path: info.destinationURL.path, underlyingError: error
            )
            updateSleepPrevention()
            return
        }

        Task {
            let written = await sessionDelegate.fileWriter.getBytesWritten(for: zimFileID)
            let isComplete = written >= info.expectedTotalBytes && info.expectedTotalBytes > 0
            if isComplete {
                await self.downloadCompleted(zimFileID: zimFileID)
            } else {
                Log.DownloadService.warning(
                    "Download incomplete: \(written)/\(info.expectedTotalBytes), retrying..."
                )
                self.scheduleRetry(for: zimFileID)
            }
        }
    }

    // MARK: - Download Lifecycle

    private func startURLSessionTask(zimFileID: UUID, url: URL, fromOffset offset: Int64) {
        var request = URLRequest(url: url)
        if offset > 0 {
            request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
            Log.DownloadService.info("Requesting range from byte \(offset)")
        }

        let urlTask = urlSession.dataTask(with: request)
        urlTask.taskDescription = zimFileID.uuidString
        sessionTasks[zimFileID] = urlTask

        preventSystemSleep()
        startTimers()
        urlTask.resume()
    }

    private func downloadCompleted(zimFileID: UUID) async {
        guard let info = activeDownloads[zimFileID] else { return }

        await sessionDelegate.fileWriter.close(zimFileID: zimFileID)
        let written = await sessionDelegate.fileWriter.getBytesWritten(for: zimFileID)

        Log.DownloadService.info(
            "Download completed for \(zimFileID.uuidString, privacy: .public): \(written) bytes"
        )

        DirectWriteDownloadState.remove(for: zimFileID)
        if info.securityScopedAccess {
            info.destinationURL.deletingLastPathComponent().stopAccessingSecurityScopedResource()
        }

        activeDownloads.removeValue(forKey: zimFileID)
        sessionTasks.removeValue(forKey: zimFileID)
        updateSleepPrevention()

        NotificationCenter.default.post(
            name: .directWriteDownloadCompleted,
            object: nil,
            userInfo: ["zimFileID": info.zimFileID, "fileURL": info.destinationURL]
        )
    }

    private func scheduleRetry(for zimFileID: UUID) {
        guard var info = activeDownloads[zimFileID] else { return }
        info.retryCount += 1
        activeDownloads[zimFileID] = info

        if info.retryCount > self.maxRetryAttempts {
            Log.DownloadService.error(
                "Max retry attempts reached for \(zimFileID.uuidString, privacy: .public)"
            )
            activeDownloads[zimFileID]?.isPaused = true
            activeDownloads[zimFileID]?.error = .writeError(
                path: info.destinationURL.path, underlyingError: nil
            )
            updateSleepPrevention()
            return
        }

        Log.DownloadService.info(
            "Scheduling retry \(info.retryCount)/\(self.maxRetryAttempts) for \(zimFileID.uuidString, privacy: .public)"
        )

        Task {
            try? await Task.sleep(nanoseconds: UInt64(self.retryDelay * 1_000_000_000))
            guard let currentInfo = self.activeDownloads[zimFileID],
                  !currentInfo.isPaused else { return }

            let currentOffset = await self.sessionDelegate.fileWriter.getBytesWritten(
                for: zimFileID
            )
            do {
                try await self.sessionDelegate.fileWriter.prepare(
                    zimFileID: zimFileID, url: currentInfo.destinationURL, offset: currentOffset
                )
                self.startURLSessionTask(
                    zimFileID: zimFileID, url: currentInfo.downloadURL,
                    fromOffset: currentOffset
                )
            } catch {
                self.activeDownloads[zimFileID]?.isPaused = true
                self.activeDownloads[zimFileID]?.error = .writeError(
                    path: currentInfo.destinationURL.path, underlyingError: error
                )
                self.updateSleepPrevention()
            }
        }
    }

    // MARK: - State Persistence

    private func saveState(for zimFileID: UUID) {
        guard let info = activeDownloads[zimFileID] else { return }
        Task {
            let written = await sessionDelegate.fileWriter.getBytesWritten(for: zimFileID)
            DirectWriteDownloadState(
                zimFileID: info.zimFileID,
                downloadURL: info.downloadURL,
                destinationURL: info.destinationURL,
                expectedTotalBytes: info.expectedTotalBytes
            ).withBytesWritten(written).withPaused(info.isPaused).save()
        }
    }

    private func showError(_ error: DirectWriteDownloadError, for zimFileID: UUID) {
        DownloadUI.showAlert(
            .downloadErrorZIM(zimFileID: zimFileID, errorMessage: error.localizedDescription)
        )
    }

    // MARK: - System Sleep Prevention

    private func preventSystemSleep() {
        guard sleepAssertion == nil else { return }
        sleepAssertion = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Kiwix is downloading ZIM files"
        )
    }

    private func allowSystemSleep() {
        guard let assertion = sleepAssertion else { return }
        ProcessInfo.processInfo.endActivity(assertion)
        sleepAssertion = nil
    }

    private func updateSleepPrevention() {
        let hasActive = activeDownloads.values.contains { !$0.isPaused && $0.error == nil }
        if hasActive { preventSystemSleep() } else { allowSystemSleep(); stopTimers() }
    }

    // MARK: - Timers

    private func startTimers() {
        if progressTimer == nil {
            progressTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0, repeats: true
            ) { [weak self] _ in
                Task { @MainActor [weak self] in await self?.updateProgress() }
            }
        }
        if autoSaveTimer == nil {
            autoSaveTimer = Timer.scheduledTimer(
                withTimeInterval: stateAutoSaveInterval, repeats: true
            ) { [weak self] _ in
                Task { @MainActor [weak self] in await self?.performPeriodicMaintenance() }
            }
        }
    }

    private func stopTimers() {
        progressTimer?.invalidate(); progressTimer = nil
        autoSaveTimer?.invalidate(); autoSaveTimer = nil
    }

    private func updateProgress() async {
        for (zimFileID, info) in activeDownloads where !info.isPaused && info.error == nil {
            let taskID = sessionTasks[zimFileID]?.taskIdentifier ?? -1
            let written = await sessionDelegate.fileWriter.getBytesWritten(for: zimFileID)
            let buffered = await sessionDelegate.buffer.currentSize(for: taskID)
            DownloadService.shared.progress.updateFor(
                uuid: zimFileID, downloaded: written + Int64(buffered),
                total: info.expectedTotalBytes
            )
        }
    }

    private func performPeriodicMaintenance() async {
        for (zimFileID, info) in activeDownloads where !info.isPaused && info.error == nil {
            let taskID = sessionTasks[zimFileID]?.taskIdentifier ?? -1
            let remaining = await sessionDelegate.buffer.drain(for: taskID)
            if !remaining.isEmpty {
                try? await sessionDelegate.fileWriter.write(remaining, for: zimFileID)
            }
            saveState(for: zimFileID)
        }
    }

    // MARK: - Restore Interrupted Downloads

    private func restoreInterruptedDownloads() {
        guard DownloadDestination.shouldUseDirectWrite else { return }

        let savedStates = DirectWriteDownloadState.loadAll()
        guard !savedStates.isEmpty else { return }

        Log.DownloadService.info(
            "restoreInterruptedDownloads: found \(savedStates.count) saved state(s)"
        )

        for state in savedStates where !state.isComplete {
            var hasScope = false
            if let resolvedDir = DownloadDestination.customDownloadDirectory() {
                hasScope = resolvedDir.startAccessingSecurityScopedResource()
            }

            if !state.validatePartialFile() {
                Log.DownloadService.info(
                    "Cleaning orphaned state for \(state.zimFileID.uuidString, privacy: .public)"
                )
                try? FileManager.default.removeItem(at: state.destinationURL)
                DirectWriteDownloadState.remove(for: state.zimFileID)
                if hasScope {
                    DownloadDestination.customDownloadDirectory()?
                        .stopAccessingSecurityScopedResource()
                }
                continue
            }

            let fileID = state.zimFileID.uuidString
            let progress = "\(state.bytesWritten)/\(state.expectedTotalBytes)"
            Log.DownloadService.info(
                "Found interrupted download for \(fileID, privacy: .public): \(progress) bytes"
            )

            var info = DownloadTaskInfo(
                zimFileID: state.zimFileID,
                downloadURL: state.downloadURL,
                destinationURL: state.destinationURL,
                expectedTotalBytes: state.expectedTotalBytes
            )
            info.isPaused = true
            info.securityScopedAccess = hasScope
            activeDownloads[state.zimFileID] = info

            DownloadService.shared.progress.updateFor(
                uuid: state.zimFileID, downloaded: state.bytesWritten,
                total: state.expectedTotalBytes
            )
            DownloadService.shared.progress.updateFor(
                uuid: state.zimFileID, withResumeData: Data([0x01])
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let directWriteDownloadCompleted = Notification.Name("directWriteDownloadCompleted")
}

// MARK: - Equatable for DirectWriteDownloadError

extension DirectWriteDownloadError: Equatable {
    static func == (lhs: DirectWriteDownloadError, rhs: DirectWriteDownloadError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled): return true
        case (.rangeRequestsNotSupported, .rangeRequestsNotSupported): return true
        case let (.destinationNotAccessible(path1), .destinationNotAccessible(path2)):
            return path1 == path2
        case let (.insufficientDiskSpace(req1, avail1), .insufficientDiskSpace(req2, avail2)):
            return req1 == req2 && avail1 == avail2
        case let (.volumeUnmounted(path1), .volumeUnmounted(path2)):
            return path1 == path2
        case let (.partialFileCorrupted(path1), .partialFileCorrupted(path2)):
            return path1 == path2
        case let (.invalidServerResponse(code1), .invalidServerResponse(code2)):
            return code1 == code2
        default: return false
        }
    }
}
#endif

// swiftlint:enable file_length
