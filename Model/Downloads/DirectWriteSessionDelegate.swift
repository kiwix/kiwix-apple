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

// MARK: - DownloadDataBuffer Actor

/// Actor that buffers incoming download data in RAM.
/// The hot-path delegate callback only interacts with this actor.
actor DownloadDataBuffer {
    private var buffers: [Int: Data] = [:]
    private let flushThreshold: Int

    init(flushThreshold: Int) {
        self.flushThreshold = flushThreshold
    }

    /// Appends data for a task. If the buffer exceeds the threshold,
    /// atomically drains and returns it for flushing. Returns nil otherwise.
    func append(_ data: Data, for taskID: Int) -> Data? {
        buffers[taskID, default: Data()].append(data)
        guard let count = buffers[taskID]?.count, count >= flushThreshold else {
            return nil
        }
        let toFlush = buffers.removeValue(forKey: taskID)
        buffers[taskID] = Data()
        buffers[taskID]?.reserveCapacity(flushThreshold)
        return toFlush
    }

    /// Drains remaining buffer (for final flush, pause, or cancel).
    func drain(for taskID: Int) -> Data {
        buffers.removeValue(forKey: taskID) ?? Data()
    }

    func remove(for taskID: Int) {
        buffers.removeValue(forKey: taskID)
    }

    func currentSize(for taskID: Int) -> Int {
        buffers[taskID]?.count ?? 0
    }
}

// MARK: - DownloadFileWriter Actor

/// Actor that manages file I/O for direct-write downloads.
/// All disk writes are serialized through this actor.
actor DownloadFileWriter {
    private var handles: [UUID: FileHandle] = [:]
    private(set) var bytesWritten: [UUID: Int64] = [:]

    /// Opens or creates a file for writing at the given offset.
    func prepare(zimFileID: UUID, url: URL, offset: Int64) throws {
        try? handles[zimFileID]?.close()
        handles[zimFileID] = nil

        let fileManager = FileManager.default
        let path = url.path

        if offset > 0 && fileManager.fileExists(atPath: path) {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seek(toOffset: UInt64(offset))
            handles[zimFileID] = handle
            bytesWritten[zimFileID] = offset
            Log.DownloadService.info("Opened existing file for resume at offset \(offset)")
        } else {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(at: url)
            }
            guard fileManager.createFile(atPath: path, contents: nil, attributes: nil) else {
                throw DirectWriteDownloadError.cannotCreateFile(
                    path: path, underlyingError: nil
                )
            }
            handles[zimFileID] = try FileHandle(forWritingTo: url)
            bytesWritten[zimFileID] = 0
            Log.DownloadService.info("Created new file for download")
        }
    }

    /// Writes data to disk for a given download. Returns total bytes written.
    @discardableResult
    func write(_ data: Data, for zimFileID: UUID) throws -> Int64 {
        guard let handle = handles[zimFileID], !data.isEmpty else {
            return bytesWritten[zimFileID] ?? 0
        }
        try handle.write(contentsOf: data)
        bytesWritten[zimFileID, default: 0] += Int64(data.count)
        return bytesWritten[zimFileID] ?? 0
    }

    /// Syncs and closes the file handle.
    func close(zimFileID: UUID) {
        if let handle = handles[zimFileID] {
            try? handle.synchronize()
            try? handle.close()
        }
        handles.removeValue(forKey: zimFileID)
    }

    func getBytesWritten(for zimFileID: UUID) -> Int64 {
        bytesWritten[zimFileID] ?? 0
    }

    func remove(zimFileID: UUID) {
        handles.removeValue(forKey: zimFileID)
        bytesWritten.removeValue(forKey: zimFileID)
    }
}

// MARK: - DirectWriteSessionDelegate

/// URLSessionDataDelegate for the direct-write download path on macOS.
/// Handles the hot-path data flow: buffer incoming data, flush to disk when threshold reached.
/// Communicates back to DirectWriteDownloadService via `onFlush` and `onCompletion` callbacks.
///
/// Architecture mirrors upstream's DownloadSessionDelegate (separate delegate from service).
@MainActor
final class DirectWriteSessionDelegate: NSObject, URLSessionDataDelegate {

    let buffer: DownloadDataBuffer
    let fileWriter: DownloadFileWriter

    /// Called on MainActor after a buffer flush writes data to disk.
    /// Parameters: (zimFileID, totalBytesWritten)
    var onFlush: (@MainActor @Sendable (UUID, Int64) -> Void)?

    /// Called on MainActor when a URLSession task completes (success or error).
    /// Parameters: (zimFileID, error)
    var onCompletion: (@MainActor @Sendable (UUID, (any Error)?) -> Void)?

    init(buffer: DownloadDataBuffer, fileWriter: DownloadFileWriter) {
        self.buffer = buffer
        self.fileWriter = fileWriter
    }

    // MARK: - URLSessionDataDelegate

    nonisolated func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        completionHandler([200, 206].contains(httpResponse.statusCode) ? .allow : .cancel)
    }

    /// Called for each chunk of data received.
    /// PERFORMANCE CRITICAL: ~780 calls/sec at 400Mbps.
    /// Only touches the buffer actor — no MainActor, no locks.
    nonisolated func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data
    ) {
        guard let zimFileID = UUID(uuidString: dataTask.taskDescription ?? "") else { return }
        let taskID = dataTask.taskIdentifier

        Task { [buffer, fileWriter] in
            guard let dataToFlush = await buffer.append(data, for: taskID) else { return }
            let written = try await fileWriter.write(dataToFlush, for: zimFileID)
            await MainActor.run { [weak self] in
                self?.onFlush?(zimFileID, written)
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task urlSessionTask: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        guard let zimFileID = UUID(uuidString: urlSessionTask.taskDescription ?? "") else {
            return
        }
        let taskID = urlSessionTask.taskIdentifier

        Task { [buffer, fileWriter] in
            let remaining = await buffer.drain(for: taskID)
            if !remaining.isEmpty {
                try? await fileWriter.write(remaining, for: zimFileID)
            }
            await MainActor.run { [weak self] in
                self?.onCompletion?(zimFileID, error)
            }
        }
    }
}
#endif
