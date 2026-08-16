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
import OSLog

@MainActor protocol ZIMCookiePersistence {
    func load() -> [UUID: String]
    func save(_ values: [UUID: String])
}

@MainActor
final class CookiePersistenceInFiles: ZIMCookiePersistence {
    private let fileURL: URL
    private let debouncer: Debouncer
    init() {
        fileURL = URL.documentsDirectory.appending(component: "zimCookies.json", directoryHint: .notDirectory)
        debouncer = Debouncer()
    }
    func load() -> [UUID: String] {
        let path = fileURL.path()
        guard FileManager.default.fileExists(atPath: path) else {
            return [:]
        }
        guard let data = FileManager.default.contents(atPath: path) else {
            Log.Cookies.error("unable to read data from file \(path)")
            return [:]
        }
        guard let values: [UUID: String] = try? JSONDecoder().decode([UUID: String].self, from: data) else {
            Log.Cookies.error("unable to decode data from: \(path)")
            return [:]
        }
        return values
    }

    func save(_ values: [UUID: String]) {
        let fileURL = self.fileURL
        debouncer.debounce(milliseconds: 1500) {
            await Self.saveToFile(values, fileURL: fileURL)
        }
    }
    
    nonisolated private static func saveToFile(_ values: [UUID: String], fileURL: URL) async {
        guard let data = try? JSONEncoder().encode(values) else {
#if DEBUG
            Log.Cookies.error("cannot encode data: \(values)")
#else
            Log.Cookies.error("cannot encode data: \(values.count)")
#endif
            return
        }
        let path = fileURL.path()
        do {
            if !FileManager.default.fileExists(atPath: path) {
                if FileManager.default.createFile(atPath: path, contents: data) {
                    Log.Cookies.info("created and saved data to: \(path)")
                } else {
                    Log.Cookies.error("couldn't create and write data to: \(path)")
                }
            } else {
                try data.write(to: fileURL, options: [.atomic])
                Log.Cookies.info("saved data to: \(path)")
            }
        } catch {
            Log.Cookies.error("unable to write data to: \(path)")
        }
    }
}
