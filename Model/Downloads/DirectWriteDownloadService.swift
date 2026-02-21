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

#if os(macOS)
import Foundation
import Combine
import AppKit

/// Service for downloading files directly to a custom directory on macOS.
/// Uses URLSessionDataDelegate with 16MB memory buffer for efficient disk writes.
///
/// Performance note: URLSession delegates are called on a background queue.
/// To avoid costly context switches to MainActor for every data chunk (~780/sec at 400Mbps),
/// we maintain a thread-safe task registry separate from the @Published activeDownloads.
final class DirectWriteDownloadService: NSObject, ObservableObject, URLSessionDataDelegate {
    
    // MARK: - Singleton
    
    static let shared = DirectWriteDownloadService()
    
    // MARK: - Published Properties (UI only - updated infrequently)
    
    @MainActor @Published private(set) var activeDownloads: [UUID: DownloadTask] = [:]
    
    // MARK: - Configuration Constants
    
    /// Buffer size before flushing to disk (16MB - optimal for external drives)
    private let writeBufferSize = 16 * 1024 * 1024
    
    /// Maximum time between disk flushes (30 seconds)
    private let maxFlushInterval: TimeInterval = 30
    
    /// Interval for state auto-save (30 seconds)
    private let stateAutoSaveInterval: TimeInterval = 30
    
    /// Maximum retry attempts for recoverable network errors
    private let maxRetryAttempts = 5
    
    /// Delay between retry attempts
    private let retryDelay: TimeInterval = 3.0
    
    // MARK: - Private Properties
    
    private var urlSession: URLSession!
    private var sleepAssertion: NSObjectProtocol?
    private var autoSaveTimer: Timer?
    private var wakeObserver: NSObjectProtocol?
    
    /// Thread-safe task registry - accessed from URLSession delegate without MainActor
    /// Protected by tasksLock
    private var tasks: [UUID: DownloadTask] = [:]
    private let tasksLock = NSLock()
    
    /// Maps URLSessionTask identifiers to ZIM file IDs (for delegate callbacks)
    /// Protected by tasksLock
    private var taskIDToZimFileID: [Int: UUID] = [:]
    
    /// Dedicated queue for file I/O operations
    private let fileIOQueue = DispatchQueue(label: "org.kiwix.directwrite.fileio", qos: .userInitiated)
    
    // MARK: - Nested Types
    
    /// Marked as @unchecked Sendable because we manage thread safety manually via tasksLock/fileIOQueue
    class DownloadTask: @unchecked Sendable {
        let zimFileID: UUID
        let downloadURL: URL
        let destinationURL: URL
        let expectedTotalBytes: Int64
        
        /// Bytes confirmed written to disk (access via fileIOQueue)
        var bytesWritten: Int64 = 0
        
        /// In-memory buffer for efficient disk writes (access via fileIOQueue)
        var dataBuffer = Data()
        
        /// Paused state (access via tasksLock)
        var isPaused: Bool = false
        
        /// Error state (access via tasksLock)
        var error: DirectWriteDownloadError?
        
        var urlSessionTask: URLSessionDataTask?
        var fileHandle: FileHandle?
        var securityScopedAccess: Bool = false
        var lastFlushTime: Date = Date()
        var lastSaveTime: Date = Date()
        var lastUIUpdateTime: Date = Date()
        var lastLoggedPercentage: Int = -1
        var retryCount: Int = 0
        
        var progress: Double {
            guard expectedTotalBytes > 0 else { return 0 }
            return Double(bytesWritten + Int64(dataBuffer.count)) / Double(expectedTotalBytes)
        }
        
        var totalBytesReceived: Int64 {
            return bytesWritten + Int64(dataBuffer.count)
        }
        
        var isComplete: Bool {
            bytesWritten >= expectedTotalBytes && expectedTotalBytes > 0
        }
        
        init(zimFileID: UUID, downloadURL: URL, destinationURL: URL, expectedTotalBytes: Int64) {
            self.zimFileID = zimFileID
            self.downloadURL = downloadURL
            self.destinationURL = destinationURL
            self.expectedTotalBytes = expectedTotalBytes
        }
    }
    
    // MARK: - Thread-Safe Task Access
    
    /// Gets a task by ZIM file ID (thread-safe)
    private func getTask(for zimFileID: UUID) -> DownloadTask? {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        return tasks[zimFileID]
    }
    
    /// Gets a task by URLSessionTask identifier (thread-safe)
    private func getTask(forSessionTaskID taskID: Int) -> DownloadTask? {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        guard let zimFileID = taskIDToZimFileID[taskID] else { return nil }
        return tasks[zimFileID]
    }
    
    /// Registers a task (thread-safe)
    private func registerTask(_ task: DownloadTask) {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        tasks[task.zimFileID] = task
    }
    
    /// Unregisters a task (thread-safe)
    private func unregisterTask(for zimFileID: UUID) {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        tasks.removeValue(forKey: zimFileID)
    }
    
    /// Maps URLSessionTask ID to ZIM file ID (thread-safe)
    private func mapSessionTask(_ sessionTaskID: Int, to zimFileID: UUID) {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        taskIDToZimFileID[sessionTaskID] = zimFileID
    }
    
    /// Removes URLSessionTask ID mapping and returns the ZIM file ID (thread-safe)
    private func unmapSessionTask(_ sessionTaskID: Int) -> UUID? {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        return taskIDToZimFileID.removeValue(forKey: sessionTaskID)
    }
    
    /// Checks if task is paused (thread-safe)
    private func isTaskPaused(_ task: DownloadTask) -> Bool {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        return task.isPaused
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 0
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = true
        
        // Use dedicated queue for URLSession callbacks (not main thread)
        let sessionQueue = OperationQueue()
        sessionQueue.name = "org.kiwix.directwrite.session"
        sessionQueue.maxConcurrentOperationCount = 1
        
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: sessionQueue)
        
        setupWakeObserver()
        
        Task { @MainActor in
            restoreInterruptedDownloads()
        }
    }
    
    deinit {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    // MARK: - Wake Observer
    
    private func setupWakeObserver() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWake()
        }
    }
    
    private func handleSystemWake() {
        Log.DownloadService.info("System woke from sleep, checking downloads...")
        
        Task { @MainActor in
            for (zimFileID, task) in activeDownloads {
                if task.error != nil && !task.isPaused {
                    Log.DownloadService.info("Auto-resuming download for \(zimFileID.uuidString, privacy: .public)")
                    task.retryCount = 0
                    task.error = nil
                    await resume(zimFileID: zimFileID)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func start(zimFileID: UUID, downloadURL: URL, expectedSize: Int64, allowsCellularAccess: Bool = true) async {
        guard activeDownloads[zimFileID] == nil else {
            Log.DownloadService.warning("Download already in progress for \(zimFileID.uuidString, privacy: .public)")
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
        
        let validation = DownloadDestination.validateDestination(directory: directory, requiredBytes: expectedSize)
        
        switch validation {
        case .valid:
            break
        case .notAccessible, .notWritable:
            Log.DownloadService.error("Directory not accessible: \(directory.path, privacy: .public)")
            await showError(.destinationNotAccessible(path: directory.path), for: zimFileID)
            if needsSecurityScope { directory.stopAccessingSecurityScopedResource() }
            return
        case .insufficientSpace(let required, let available):
            Log.DownloadService.error("Insufficient disk space")
            await showError(.insufficientDiskSpace(required: required, available: available), for: zimFileID)
            if needsSecurityScope { directory.stopAccessingSecurityScopedResource() }
            return
        }
        
        var resumeOffset: Int64 = 0
        if let state = DirectWriteDownloadState.load(for: zimFileID), state.validatePartialFile() {
            resumeOffset = state.bytesWritten
            Log.DownloadService.info("Resuming download from byte \(resumeOffset)")
        }
        
        let task = DownloadTask(
            zimFileID: zimFileID,
            downloadURL: downloadURL,
            destinationURL: destinationURL,
            expectedTotalBytes: expectedSize
        )
        task.bytesWritten = resumeOffset
        task.securityScopedAccess = needsSecurityScope
        task.dataBuffer.reserveCapacity(writeBufferSize)
        
        do {
            try prepareFileForWriting(task: task, resumeFrom: resumeOffset)
        } catch {
            Log.DownloadService.error("Failed to prepare file: \(error.localizedDescription, privacy: .public)")
            if needsSecurityScope { directory.stopAccessingSecurityScopedResource() }
            return
        }
        
        // Register in both maps
        registerTask(task)
        activeDownloads[zimFileID] = task
        
        startDownloadTask(task, fromOffset: resumeOffset)

        // Save initial state immediately so download survives early app termination
        let initialState = DirectWriteDownloadState(
            zimFileID: zimFileID,
            downloadURL: downloadURL,
            destinationURL: destinationURL,
            expectedTotalBytes: expectedSize
        ).withBytesWritten(resumeOffset)
        initialState.save()

        // Initialize progress in UI immediately (same pattern as background downloads)
        DownloadService.shared.progress.updateFor(
            uuid: zimFileID,
            downloaded: resumeOffset,
            total: expectedSize
        )

        Log.DownloadService.info("Started direct-write download for \(zimFileID.uuidString, privacy: .public) to \(destinationURL.path, privacy: .public)")

        // Log initial 0% progress
        if task.expectedTotalBytes > 0 {
            Log.DownloadService.info(
                "Download progress: 0% (Zero KB / \(ByteCountFormatter.string(fromByteCount: task.expectedTotalBytes, countStyle: .file)))"
            )
            task.lastLoggedPercentage = 0
        }
    }
    
    @MainActor
    func pause(zimFileID: UUID) {
        guard let task = activeDownloads[zimFileID], !task.isPaused else { return }
        
        // Mark as paused (thread-safe)
        tasksLock.lock()
        task.isPaused = true
        tasksLock.unlock()
        
        task.urlSessionTask?.cancel()
        
        // Flush buffer to disk before pausing
        fileIOQueue.sync {
            self.flushBufferToDisk(task: task)
        }
        
        saveState(for: task)
        
        // Signal to UI that download is paused
        let placeholderResumeData = Data([0x01])
        DownloadService.shared.progress.updateFor(uuid: zimFileID, withResumeData: placeholderResumeData)
        
        Log.DownloadService.info("Paused download for \(zimFileID.uuidString, privacy: .public) at \(task.bytesWritten) bytes")
        
        updateSleepPrevention()
    }
    
    @MainActor
    func resume(zimFileID: UUID) async {
        guard let task = activeDownloads[zimFileID] else { return }
        
        // Check state (thread-safe)
        tasksLock.lock()
        let wasPausedOrError = task.isPaused || task.error != nil
        task.isPaused = false
        task.error = nil
        tasksLock.unlock()
        
        guard wasPausedOrError else { return }
        
        // Get current offset from I/O queue
        let currentOffset = fileIOQueue.sync { task.bytesWritten }
        
        // Clear resume data so UI switches from "Resume" back to "Pause"
        DownloadService.shared.progress.updateFor(uuid: zimFileID, withResumeData: nil)

        // Update progress with current offset
        DownloadService.shared.progress.updateFor(
            uuid: zimFileID,
            downloaded: currentOffset,
            total: task.expectedTotalBytes
        )
        
        // Ensure security-scoped access from resolved bookmark before reopening file
        if !task.securityScopedAccess {
            if let resolvedDir = DownloadDestination.customDownloadDirectory() {
                task.securityScopedAccess = resolvedDir.startAccessingSecurityScopedResource()
            }
        }

        // Check if file handle needs reopening
        let needsReopen = fileIOQueue.sync { task.fileHandle == nil }

        if needsReopen {
            do {
                try prepareFileForWriting(task: task, resumeFrom: currentOffset)
            } catch {
                Log.DownloadService.error("Failed to reopen file: \(error.localizedDescription, privacy: .public)")
                tasksLock.lock()
                task.error = .cannotCreateFile(path: task.destinationURL.path, underlyingError: error)
                tasksLock.unlock()
                return
            }
        }
        
        startDownloadTask(task, fromOffset: currentOffset)
        
        Log.DownloadService.info("Resumed download for \(zimFileID.uuidString, privacy: .public) from byte \(currentOffset)")
    }
    
    @MainActor
    func cancel(zimFileID: UUID) {
        guard let task = activeDownloads[zimFileID] else { return }
        
        task.urlSessionTask?.cancel()
        
        // Close file handle safely on I/O queue
        fileIOQueue.sync {
            try? task.fileHandle?.close()
            task.fileHandle = nil
        }
        
        try? FileManager.default.removeItem(at: task.destinationURL)
        
        if task.securityScopedAccess {
            task.destinationURL.deletingLastPathComponent().stopAccessingSecurityScopedResource()
        }
        
        // Unregister from both maps
        if let taskId = task.urlSessionTask?.taskIdentifier {
            _ = unmapSessionTask(taskId)
        }
        unregisterTask(for: zimFileID)
        
        DirectWriteDownloadState.remove(for: zimFileID)
        activeDownloads.removeValue(forKey: zimFileID)
        
        Log.DownloadService.info("Cancelled download for \(zimFileID.uuidString, privacy: .public)")
        
        updateSleepPrevention()
    }
    
    // MARK: - Private Methods - Download Control
    
    private func startDownloadTask(_ task: DownloadTask, fromOffset offset: Int64) {
        var request = URLRequest(url: task.downloadURL)
        if offset > 0 {
            request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
            Log.DownloadService.info("Requesting range from byte \(offset)")
        }
        
        let urlTask = urlSession.dataTask(with: request)
        task.urlSessionTask = urlTask
        task.lastFlushTime = Date()
        
        mapSessionTask(urlTask.taskIdentifier, to: task.zimFileID)
        
        preventSystemSleep()
        startAutoSaveTimer()
        
        urlTask.resume()
    }
    
    /// Flushes the in-memory buffer to disk. Must be called on fileIOQueue.
    private func flushBufferToDisk(task: DownloadTask) {
        guard !task.dataBuffer.isEmpty, let fileHandle = task.fileHandle else { return }

        let flushedBytes = Int64(task.dataBuffer.count)

        do {
            try fileHandle.write(contentsOf: task.dataBuffer)
            let previousWritten = task.bytesWritten
            task.bytesWritten += flushedBytes
            task.dataBuffer.removeAll(keepingCapacity: true)
            task.lastFlushTime = Date()

            // Log progress at 10% milestones (~10 lines per download, regardless of file size)
            if task.expectedTotalBytes > 0 {
                let percentage = Int(task.bytesWritten * 100 / task.expectedTotalBytes)
                let milestone = percentage / 10 * 10
                if milestone > task.lastLoggedPercentage {
                    task.lastLoggedPercentage = milestone
                    Log.DownloadService.info(
                        "Download progress: \(milestone)% (\(ByteCountFormatter.string(fromByteCount: task.bytesWritten, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: task.expectedTotalBytes, countStyle: .file)))"
                    )
                }
            } else {
                // Unknown total size: log every 500MB
                let mb500 = Int64(500 * 1024 * 1024)
                if task.bytesWritten / mb500 > previousWritten / mb500 {
                    Log.DownloadService.info(
                        "Download progress: \(ByteCountFormatter.string(fromByteCount: task.bytesWritten, countStyle: .file)) written"
                    )
                }
            }
        } catch {
            Log.DownloadService.error("Failed to flush buffer: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func scheduleRetry(for task: DownloadTask) {
        task.retryCount += 1
        
        if task.retryCount > maxRetryAttempts {
            Log.DownloadService.error("Max retry attempts reached for \(task.zimFileID.uuidString, privacy: .public)")
            Task { @MainActor in
                tasksLock.lock()
                task.isPaused = true
                task.error = .writeError(path: task.destinationURL.path, underlyingError: nil)
                tasksLock.unlock()
                updateSleepPrevention()
            }
            return
        }
        
        Log.DownloadService.info("Scheduling retry \(task.retryCount)/\(self.maxRetryAttempts) for \(task.zimFileID.uuidString, privacy: .public)")
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            
            await MainActor.run {
                // Check if still not paused
                guard !self.isTaskPaused(task) else { return }
                
                let currentOffset = self.fileIOQueue.sync { task.bytesWritten }
                
                do {
                    try self.prepareFileForWriting(task: task, resumeFrom: currentOffset)
                    self.startDownloadTask(task, fromOffset: currentOffset)
                } catch {
                    self.tasksLock.lock()
                    task.isPaused = true
                    task.error = .writeError(path: task.destinationURL.path, underlyingError: error)
                    self.tasksLock.unlock()
                    self.updateSleepPrevention()
                }
            }
        }
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        let validCodes = [200, 206]
        if validCodes.contains(httpResponse.statusCode) {
            completionHandler(.allow)
        } else {
            Log.DownloadService.error("Invalid response code: \(httpResponse.statusCode)")
            completionHandler(.cancel)
        }
    }
    
    /// Called for each chunk of data received.
    /// PERFORMANCE CRITICAL: This is called ~780 times/second at 400Mbps.
    /// We avoid MainActor dispatch here - all work happens on sessionQueue + fileIOQueue.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Get task without going through MainActor (thread-safe via tasksLock)
        guard let task = getTask(forSessionTaskID: dataTask.taskIdentifier) else { return }
        
        // Check if paused (thread-safe)
        if isTaskPaused(task) { return }
        
        // Process data on I/O queue (no MainActor involved)
        fileIOQueue.async { [self] in
            // Append to buffer
            task.dataBuffer.append(data)
            
            // Update UI progress every ~1 second (lightweight, no disk I/O)
            let now = Date()
            if now.timeIntervalSince(task.lastUIUpdateTime) >= 1.0 {
                task.lastUIUpdateTime = now
                let totalReceived = task.bytesWritten + Int64(task.dataBuffer.count)
                let total = task.expectedTotalBytes
                let zimFileID = task.zimFileID
                DispatchQueue.main.async {
                    DownloadService.shared.progress.updateFor(
                        uuid: zimFileID,
                        downloaded: totalReceived,
                        total: total
                    )
                }
            }

            let bufferSize = task.dataBuffer.count
            let timeSinceFlush = now.timeIntervalSince(task.lastFlushTime)
            let shouldFlush = bufferSize >= writeBufferSize || timeSinceFlush >= maxFlushInterval

            // Flush if buffer is full OR time threshold exceeded
            if shouldFlush {
                flushBufferToDisk(task: task)

                // Save state after every flush (1 save per 16MB — negligible overhead)
                DispatchQueue.main.async {
                    self.saveState(for: task)
                }

                // Update progress only on flush (not every chunk)
                // This reduces MainActor dispatches from ~780/s to ~3/s (every 16MB)
                let totalWritten = task.bytesWritten
                let total = task.expectedTotalBytes
                let zimFileID = task.zimFileID
                
                DispatchQueue.main.async {
                    DownloadService.shared.progress.updateFor(
                        uuid: zimFileID,
                        downloaded: totalWritten,
                        total: total
                    )
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task urlSessionTask: URLSessionTask, didCompleteWithError error: Error?) {
        // Get and unmap task
        guard let zimFileID = unmapSessionTask(urlSessionTask.taskIdentifier),
              let task = getTask(for: zimFileID) else { return }
        
        // Always flush remaining buffer first (on I/O queue)
        fileIOQueue.sync {
            flushBufferToDisk(task: task)
        }

        // Save state after final flush (ensures at least one save even for fast downloads)
        DispatchQueue.main.async {
            self.saveState(for: task)
        }

        if let error = error {
            let nsError = error as NSError
            
            // Check if cancelled by user (pause)
            if nsError.code == NSURLErrorCancelled && isTaskPaused(task) {
                Log.DownloadService.info("Download paused for \(zimFileID.uuidString, privacy: .public)")
                return
            }
            
            Log.DownloadService.error("Download failed for \(zimFileID.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            
            // Save current progress
            Task { @MainActor in
                self.saveState(for: task)
            }
            
            // Check if recoverable
            let recoverableCodes = [
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorTimedOut,
                NSURLErrorCannotConnectToHost,
                NSURLErrorCannotFindHost
            ]
            
            if recoverableCodes.contains(nsError.code) {
                scheduleRetry(for: task)
                return
            }
            
            // Non-recoverable error
            tasksLock.lock()
            task.isPaused = true
            task.error = .writeError(path: task.destinationURL.path, underlyingError: error)
            tasksLock.unlock()
            
            Task { @MainActor in
                self.updateSleepPrevention()
            }
            return
        }
        
        // Success - check if complete
        let (isComplete, bytesWritten) = fileIOQueue.sync {
            (task.isComplete, task.bytesWritten)
        }
        
        if isComplete {
            // Close file handle safely on I/O queue
            fileIOQueue.sync {
                try? task.fileHandle?.synchronize()
                try? task.fileHandle?.close()
                task.fileHandle = nil
            }
            
            Task { @MainActor in
                await self.downloadCompleted(task: task)
            }
        } else {
            // Server closed connection early - retry
            Log.DownloadService.warning("Download incomplete: \(bytesWritten)/\(task.expectedTotalBytes), retrying...")
            scheduleRetry(for: task)
        }
    }
    
    // MARK: - File Handling
    
    private func prepareFileForWriting(task: DownloadTask, resumeFrom offset: Int64) throws {
        let fileManager = FileManager.default
        let path = task.destinationURL.path
        
        // Close existing handle if any (safely)
        try? task.fileHandle?.close()
        task.fileHandle = nil
        
        if offset > 0 && fileManager.fileExists(atPath: path) {
            task.fileHandle = try FileHandle(forWritingTo: task.destinationURL)
            try task.fileHandle?.seek(toOffset: UInt64(offset))
            Log.DownloadService.info("Opened existing file for resume at offset \(offset)")
        } else {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(at: task.destinationURL)
            }
            
            guard fileManager.createFile(atPath: path, contents: nil, attributes: nil) else {
                throw DirectWriteDownloadError.cannotCreateFile(path: path, underlyingError: nil)
            }
            
            task.fileHandle = try FileHandle(forWritingTo: task.destinationURL)
            task.bytesWritten = 0
            Log.DownloadService.info("Created new file for download")
        }
    }
    
    @MainActor
    private func downloadCompleted(task: DownloadTask) async {
        Log.DownloadService.info("Download completed for \(task.zimFileID.uuidString, privacy: .public): \(task.bytesWritten) bytes")
        
        DirectWriteDownloadState.remove(for: task.zimFileID)
        
        if task.securityScopedAccess {
            task.destinationURL.deletingLastPathComponent().stopAccessingSecurityScopedResource()
        }
        
        // Unregister from both maps
        unregisterTask(for: task.zimFileID)
        activeDownloads.removeValue(forKey: task.zimFileID)
        
        updateSleepPrevention()
        
        NotificationCenter.default.post(
            name: .directWriteDownloadCompleted,
            object: nil,
            userInfo: [
                "zimFileID": task.zimFileID,
                "fileURL": task.destinationURL
            ]
        )
    }
    
    @MainActor
    private func saveState(for task: DownloadTask) {
        // Don't save state for tasks that have been cancelled or completed
        guard activeDownloads[task.zimFileID] != nil else { return }

        let bytesWritten = fileIOQueue.sync { task.bytesWritten }
        let isPaused = isTaskPaused(task)
        
        let state = DirectWriteDownloadState(
            zimFileID: task.zimFileID,
            downloadURL: task.downloadURL,
            destinationURL: task.destinationURL,
            expectedTotalBytes: task.expectedTotalBytes
        ).withBytesWritten(bytesWritten)
         .withPaused(isPaused)
        
        state.save()
        task.lastSaveTime = Date()
    }
    
    private func showError(_ error: DirectWriteDownloadError, for zimFileID: UUID) async {
        NotificationCenter.default.post(
            name: .alert,
            object: nil,
            userInfo: [
                "alert": ActiveAlert.downloadErrorZIM(
                    zimFileID: zimFileID,
                    errorMessage: error.localizedDescription
                )
            ]
        )
    }
    
    // MARK: - System Sleep Prevention
    
    private func preventSystemSleep() {
        guard sleepAssertion == nil else { return }
        
        sleepAssertion = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Kiwix is downloading ZIM files"
        )
        
        Log.DownloadService.info("System sleep prevention enabled")
    }
    
    private func allowSystemSleep() {
        guard let assertion = sleepAssertion else { return }
        
        ProcessInfo.processInfo.endActivity(assertion)
        sleepAssertion = nil
        
        Log.DownloadService.info("System sleep prevention disabled")
    }
    
    @MainActor
    private func updateSleepPrevention() {
        let hasActiveDownloads = activeDownloads.values.contains { !$0.isPaused && $0.error == nil }
        
        if hasActiveDownloads {
            preventSystemSleep()
        } else {
            allowSystemSleep()
            stopAutoSaveTimer()
        }
    }
    
    // MARK: - Auto-Save Timer
    
    private func startAutoSaveTimer() {
        guard autoSaveTimer == nil else { return }
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: stateAutoSaveInterval, repeats: true) { [weak self] _ in
            self?.performPeriodicMaintenance()
        }
    }
    
    private func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    /// Periodic maintenance: flush buffers and save state for all active downloads
    private func performPeriodicMaintenance() {
        Task { @MainActor in
            for task in activeDownloads.values where !task.isPaused {
                fileIOQueue.async { [self] in
                    self.flushBufferToDisk(task: task)
                    // Save state AFTER flush completes, on the same queue to avoid race condition
                    if Date().timeIntervalSince(task.lastSaveTime) >= stateAutoSaveInterval {
                        DispatchQueue.main.async {
                            self.saveState(for: task)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Restore Interrupted Downloads
    
    @MainActor
    private func restoreInterruptedDownloads() {
        Log.DownloadService.info("restoreInterruptedDownloads() called")

        guard DownloadDestination.shouldUseDirectWrite else {
            Log.DownloadService.info("restoreInterruptedDownloads: skipped — no custom directory")
            return
        }

        let savedStates = DirectWriteDownloadState.loadAll()

        if savedStates.isEmpty {
            Log.DownloadService.info("restoreInterruptedDownloads: no saved states found")
            return
        }

        Log.DownloadService.info("restoreInterruptedDownloads: found \(savedStates.count) saved state(s)")

        for state in savedStates where !state.isComplete {
            // Activate security scope from resolved bookmark (plain URLs don't carry scope token)
            var hasScope = false
            let resolvedDir = DownloadDestination.customDownloadDirectory()
            if let resolvedDir {
                hasScope = resolvedDir.startAccessingSecurityScopedResource()
            }

            // Validate partial file exists and matches saved state
            if !state.validatePartialFile() {
                Log.DownloadService.info("Cleaning orphaned download state for \(state.zimFileID.uuidString, privacy: .public)")
                try? FileManager.default.removeItem(at: state.destinationURL)
                DirectWriteDownloadState.remove(for: state.zimFileID)
                if hasScope, let resolvedDir { resolvedDir.stopAccessingSecurityScopedResource() }
                continue
            }

            Log.DownloadService.info(
                "Found interrupted download for \(state.zimFileID.uuidString, privacy: .public): \(state.bytesWritten)/\(state.expectedTotalBytes) bytes"
            )

            let task = DownloadTask(
                zimFileID: state.zimFileID,
                downloadURL: state.downloadURL,
                destinationURL: state.destinationURL,
                expectedTotalBytes: state.expectedTotalBytes
            )
            task.bytesWritten = state.bytesWritten
            task.isPaused = true
            task.securityScopedAccess = hasScope
            task.dataBuffer.reserveCapacity(writeBufferSize)

            // Register in both maps
            registerTask(task)
            activeDownloads[state.zimFileID] = task

            DownloadService.shared.progress.updateFor(
                uuid: task.zimFileID,
                downloaded: task.bytesWritten,
                total: task.expectedTotalBytes
            )

            // Mark as paused in UI
            let placeholderResumeData = Data([0x01])
            DownloadService.shared.progress.updateFor(uuid: task.zimFileID, withResumeData: placeholderResumeData)
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
        case (.cancelled, .cancelled):
            return true
        case (.rangeRequestsNotSupported, .rangeRequestsNotSupported):
            return true
        case let (.destinationNotAccessible(p1), .destinationNotAccessible(p2)):
            return p1 == p2
        case let (.insufficientDiskSpace(r1, a1), .insufficientDiskSpace(r2, a2)):
            return r1 == r2 && a1 == a2
        case let (.volumeUnmounted(p1), .volumeUnmounted(p2)):
            return p1 == p2
        case let (.partialFileCorrupted(p1), .partialFileCorrupted(p2)):
            return p1 == p2
        case let (.invalidServerResponse(c1), .invalidServerResponse(c2)):
            return c1 == c2
        default:
            return false
        }
    }
}
#endif
