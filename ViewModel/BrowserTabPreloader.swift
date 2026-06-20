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

import CoreData
import Foundation
import SwiftUI

/// Preload browser tabs on app start
/// Applicable on iOS mostly. On macOS all windows are loading in parallel already.
/// To really start we need 2 things completed:
/// 1) inactive tabs defined (from DB) with the selected/active tabID
/// 2) we want to start only after the first tab has been loaded
///    in order not to interfere with start up time
@MainActor final class BrowserTabPreloader {
    
    @MainActor static let shared = BrowserTabPreloader()
    private var openTabs: [NSManagedObjectID: UUID] = [:]
    private var isFirstBrowserTabLoaded = false
    private var isPreloading = false
    
    private init() {}
    
    func didLoadFirstBrowserTab() {
        Log.LibraryOperations.debug("BrowserTabPreloader::\(#function)")
        isFirstBrowserTabLoaded = true
        preload()
    }
    
    func start(with tabs: FetchedResults<Tab>, selectedTabId: NSManagedObjectID) {
        Log.LibraryOperations.debug("BrowserTabPreloader::start(with: \(tabs.count))")
        openTabs = tabs.reduce(into: [:]) { partialDict, tab in
            let tabId = tab.objectID
            // preloading is only for inactive tabs with a ZIM file
            if tabId != selectedTabId, let zimFileID = tab.zimFile?.fileID {
                partialDict[tabId] = zimFileID
            }
        }
        preload()
    }
    
    private func preload() {
        guard !isPreloading, !openTabs.isEmpty, isFirstBrowserTabLoaded else { return }
        isPreloading = true
        Log.LibraryOperations.debug("BrowserTabPreloader::preload for: \(self.openTabs.count)")
        
        let zimFileIds = Set(openTabs.values)
        let tabIDs = openTabs.keys
        Task.detached(priority: .utility) {
            for zimFileId in zimFileIds {
                _ = await ZimFileService.shared.openArchive(zimFileID: zimFileId)
                // pre-heat the ZIM file cache
                if let mainURL = await ZimFileService.shared.getMainPageURL(zimFileID: zimFileId) {
                    _ = await ZimFileService.shared.getURLContent(url: mainURL)
                }
            }
            for tabID in tabIDs {
                await MainActor.run {
                    _ = BrowserViewModel.getCached(tabID: tabID)
                }
            }
            await MainActor.run {
                self.cleanUp()
            }
        }
    }
    
    private func cleanUp() {
        openTabs.removeAll()
    }
}
