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
import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class SessionRestore: ObservableObject {
    @Published var canRestore: Bool
    
    /// During session restore we close all former windows,
    /// but we don't want the app to exit
    /// in applicationShouldTerminateAfterLastWindowClosed,
    /// so we conditionally use this flag there
    var isRestoring: Bool = false
    
    private var windowsToMenuItem: [String: String] = [:]
    private let sessionFile: URL?
    private let session: [WindowState]
    
    @MainActor static let shared = SessionRestore()

    private init() {
        sessionFile = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "session.json")
        if let sessionFile {
            session = Self.readSessionFrom(file: sessionFile)
            debugPrint(sessionFile.path())
        } else {
            Log.SessionRestore.error("session.json cannot be found or created on init")
            session = []
        }
        canRestore = !session.isEmpty
    }
    
    static func readSessionFrom(file: URL) -> [WindowState] {
        guard file.isFileURL, FileManager.default.fileExists(atPath: file.path()) else {
            Log.SessionRestore.warning("no session.json file exists yet")
            return []
        }
        do {
            let fileData = try Data(contentsOf: file)
            return try JSONDecoder().decode([WindowState].self, from: fileData)
        } catch {
            Log.SessionRestore.warning("couldn't decode session.json: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveWindows() {
        let windowStates: [WindowState] = NSApplication.shared.windows.compactMap { nsWindow in
            let windowId = nsWindow.accessibilityIdentifier()
            guard let menuItemId = windowsToMenuItem[windowId] else { return nil }
            return WindowState(window: nsWindow, menuItemId: menuItemId)
        }
        guard let json = try? JSONEncoder().encode(windowStates) else { return }
        do {
            if let sessionFile {
                try json.write(to: sessionFile)
            } else {
                Log.SessionRestore.error("the session.json was not created for write")
            }
        } catch {
            Log.SessionRestore.error("\(#function) couldn't write to session.json: \(error.localizedDescription)")
        }
    }
    
    func restore(using openWindow: @escaping (WindowState) -> Void) {
        // make sure it's a one-off action
        canRestore = false
        // make sure we're not quiting the application
        isRestoring = true
        defer {
            isRestoring = false
        }
        
        // close all current windows
        NSApplication.shared.windows.forEach { $0.close() }
        
        // re-open all saved windows
        for tabGroup in session.groupByTabs() {
            for windowState in tabGroup.value {
                openWindow(windowState)
            }
        }
    }
    
    func didChangeMenuItem(_ menuItem: MenuItem, inWindow window: NSWindow) {
        // since NSWindow.identifier isn't always unique, we need to
        // re-assigning a unique, but stable identifier to the window itself
        // using the accessibilityIdentifier for this purpose
        var windowId = window.accessibilityIdentifier()
        if windowId.isEmpty {
            windowId = UUID().uuidString
            window.setAccessibilityIdentifier(windowId)
        }
        windowsToMenuItem[windowId] = menuItem.rawValue
    }
    
    func didClose(window: NSWindow) {
        windowsToMenuItem[window.accessibilityIdentifier()] = nil
    }
}

#endif
