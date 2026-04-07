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

import Testing
@testable import Kiwix

struct DownloadDestinationTests {

    @Test(
        arguments: [
            ("Wiki-Med.ZIM", "Wiki-Med-2.zim"),
            ("ray-charles_mini_2025-11.zim", "ray-charles_mini_2025-11-2.zim")
        ]
    )
    func fileNameIncrements(fileName: String, expected: String) async throws {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = baseURL.appending(path: fileName)
        
        let same = DownloadDestination.alternateLocalPathFor(downloadURL: fileURL, count: 0)
        #expect(same.lastPathComponent == fileName)
        let next = DownloadDestination.alternateLocalPathFor(downloadURL: fileURL, count: 1)
        #expect(next.lastPathComponent == expected)
    }

    @Test
    func filePathUsesProvidedFolder() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let remoteURL = URL(string: "https://download.kiwix.org/library/test.zim")!

        let destination = DownloadDestination.filePathFor(downloadURL: remoteURL, in: folder)

        #expect(destination == folder.appendingPathComponent("test.zim"))
    }

    @Test
    func taskDestinationStoreRoundTripsAndRemoves() async throws {
        let suiteName = "DownloadDestinationTests-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let zimFileID = UUID()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Downloads", isDirectory: true)
        let snapshot = DownloadTaskDestinationSnapshot(folder: folder, folderBookmark: Data("bookmark".utf8))

        DownloadTaskDestinationStore.save(snapshot, for: zimFileID, userDefaults: userDefaults)
        #expect(DownloadTaskDestinationStore.destination(for: zimFileID, userDefaults: userDefaults) == snapshot)

        DownloadTaskDestinationStore.remove(for: zimFileID, userDefaults: userDefaults)
        #expect(DownloadTaskDestinationStore.destination(for: zimFileID, userDefaults: userDefaults) == nil)
    }

}

#if os(macOS)
struct MacDownloadLocationSelectorTests {

    @Test
    @MainActor
    func alwaysAskPromptsAndSavesSelection() async throws {
        let initial = URL(fileURLWithPath: "/tmp/initial", isDirectory: true)
        let selected = URL(fileURLWithPath: "/tmp/selected", isDirectory: true)
        var savedFolder: URL?
        var promptCount = 0

        let selector = MacDownloadLocationSelector(
            alwaysAsk: { true },
            savedLocation: { .init(state: .valid(initial), displayPath: initial.path()) },
            defaultDownloadsFolder: { initial },
            saveFolder: { savedFolder = $0 },
            chooseFolder: { initialFolder, message in
                promptCount += 1
                #expect(initialFolder == initial)
                #expect(message == "prompt")
                return selected
            }
        )

        let result = await selector.selectFolder(message: "prompt")

        #expect(result == selected)
        #expect(savedFolder == selected)
        #expect(promptCount == 1)
    }

    @Test
    @MainActor
    func useLocationSkipsPromptWhenSavedFolderIsValid() async throws {
        let saved = URL(fileURLWithPath: "/tmp/saved", isDirectory: true)
        var promptCount = 0

        let selector = MacDownloadLocationSelector(
            alwaysAsk: { false },
            savedLocation: { .init(state: .valid(saved), displayPath: saved.path()) },
            defaultDownloadsFolder: { saved },
            saveFolder: { _ in },
            chooseFolder: { _, _ in
                promptCount += 1
                return nil
            }
        )

        let result = await selector.selectFolder(message: nil)

        #expect(result == saved)
        #expect(promptCount == 0)
    }

    @Test
    @MainActor
    func useLocationFallsBackToDownloadsWithoutPromptWhenNoSavedFolderExists() async throws {
        let downloads = URL(fileURLWithPath: "/tmp/downloads", isDirectory: true)
        var promptCount = 0

        let selector = MacDownloadLocationSelector(
            alwaysAsk: { false },
            savedLocation: { .init(state: .missing, displayPath: downloads.path()) },
            defaultDownloadsFolder: { downloads },
            saveFolder: { _ in },
            chooseFolder: { _, _ in
                promptCount += 1
                return nil
            }
        )

        let result = await selector.selectFolder(message: nil)

        #expect(result == downloads)
        #expect(promptCount == 0)
    }

    @Test
    @MainActor
    func useLocationPromptsWhenSavedFolderIsInvalid() async throws {
        let downloads = URL(fileURLWithPath: "/tmp/downloads", isDirectory: true)
        let selected = URL(fileURLWithPath: "/tmp/reselected", isDirectory: true)
        var promptCount = 0

        let selector = MacDownloadLocationSelector(
            alwaysAsk: { false },
            savedLocation: { .init(state: .invalid, displayPath: "/Volumes/External/Kiwix") },
            defaultDownloadsFolder: { downloads },
            saveFolder: { _ in },
            chooseFolder: { initialFolder, _ in
                promptCount += 1
                #expect(initialFolder == downloads)
                return selected
            }
        )

        let result = await selector.selectFolder(message: nil)

        #expect(result == selected)
        #expect(promptCount == 1)
    }

    @Test
    func macStreamingStoreUsesPartialFileSizeForResumeData() async throws {
        let suiteName = "MacStreamingDownloadStoreTests-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appendingPathComponent("test.zim")
        let partial = DownloadDestination.partialFilePathFor(destination: destination)
        try Data("partial-data".utf8).write(to: partial)

        let snapshot = DownloadTaskDestinationSnapshot(folder: folder, folderBookmark: nil)
        let metadata = MacStreamingDownloadMetadata(
            sourceURL: URL(string: "https://download.kiwix.org/library/test.zim")!,
            allowsCellularAccess: false,
            destinationSnapshot: snapshot,
            destinationPath: destination.path(),
            partialFilePath: partial.path(),
            expectedTotalBytes: 128,
            entityTag: "etag",
            lastModified: "today"
        )

        let zimFileID = UUID()
        MacStreamingDownloadStore.save(metadata, for: zimFileID, userDefaults: userDefaults)

        let resumeData = try #require(MacStreamingDownloadStore.resumeData(for: zimFileID, userDefaults: userDefaults))
        let decoded = try JSONDecoder().decode(MacStreamingResumeData.self, from: resumeData)

        #expect(decoded.downloadedBytes == Int64(Data("partial-data".utf8).count))
        #expect(decoded.expectedTotalBytes == 128)
        #expect(decoded.destinationURL == destination)
        #expect(decoded.partialFileURL == partial)
    }

    @Test
    func macStreamingRegistryWritesChunksToPartialFile() async throws {
        let registry = MacStreamingDownloadRegistry()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appendingPathComponent("test.zim")
        let partial = DownloadDestination.partialFilePathFor(destination: destination)
        FileManager.default.createFile(atPath: partial.path(), contents: nil)
        let fileHandle = try FileHandle(forWritingTo: partial)
        let zimFileID = UUID()

        registry.register(
            taskID: 1,
            zimFileID: zimFileID,
            sourceURL: URL(string: "https://download.kiwix.org/library/test.zim")!,
            allowsCellularAccess: false,
            folderURL: folder,
            didAccessSecurityScopedResource: false,
            destinationSnapshot: DownloadTaskDestinationSnapshot(folder: folder, folderBookmark: nil),
            destinationURL: destination,
            partialFileURL: partial,
            expectedTotalBytes: 12,
            downloadedBytes: 0,
            fileHandle: fileHandle
        )

        let response = try #require(HTTPURLResponse(
            url: URL(string: "https://download.kiwix.org/library/test.zim")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        let preparedResponse = try registry.prepareResponse(taskID: 1, response: response)
        let prepared = try #require(preparedResponse)
        #expect(prepared.totalBytes == 12)

        let maybeProgress = try registry.append(data: Data("hello".utf8), taskID: 1)
        let progress = try #require(maybeProgress)
        #expect(progress.downloadedBytes == 5)
        #expect(progress.totalBytes == 12)

        let metadata = try #require(registry.finish(taskID: 1))
        #expect(metadata.destinationURL == destination)
        #expect(try Data(contentsOf: partial) == Data("hello".utf8))
    }

    @Test
    func macStreamingRegistryResetsPartialFileWhenResumeResponseFallsBackTo200() async throws {
        let registry = MacStreamingDownloadRegistry()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appendingPathComponent("test.zim")
        let partial = DownloadDestination.partialFilePathFor(destination: destination)
        try Data("old".utf8).write(to: partial)
        let fileHandle = try FileHandle(forWritingTo: partial)
        try fileHandle.seekToEnd()

        registry.register(
            taskID: 2,
            zimFileID: UUID(),
            sourceURL: URL(string: "https://download.kiwix.org/library/test.zim")!,
            allowsCellularAccess: false,
            folderURL: folder,
            didAccessSecurityScopedResource: false,
            destinationSnapshot: DownloadTaskDestinationSnapshot(folder: folder, folderBookmark: nil),
            destinationURL: destination,
            partialFileURL: partial,
            expectedTotalBytes: 9,
            downloadedBytes: 3,
            fileHandle: fileHandle
        )

        let response = try #require(HTTPURLResponse(
            url: URL(string: "https://download.kiwix.org/library/test.zim")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        _ = try registry.prepareResponse(taskID: 2, response: response)
        _ = try registry.append(data: Data("new".utf8), taskID: 2)
        _ = registry.finish(taskID: 2)

        #expect(try Data(contentsOf: partial) == Data("new".utf8))
    }
}
#endif
