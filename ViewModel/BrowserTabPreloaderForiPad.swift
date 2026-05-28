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
import CoreData
import Foundation
import SwiftUI

/// Preload browser tabs, only for iPad
/// to really start we need 2 components aligned in time:
/// inactive tabs defined (from DB)
/// the selected tab browser view model .isLoadeding = false
/// We want to start only after the first tab has been loaded
/// via NotificationCenter .browserTabLoaded
/// in order not to interfere with start up time
@MainActor final class BrowserTabPreloader {
    
    private var openTabs: [NSManagedObjectID: UUID] = [:]
    private var isStarted = false
    private var task: Task<Void, Never>?
    
    func start(with inactiveTabs: [NSManagedObjectID: UUID]) {
        guard task == nil else { return } // can be started only once
        guard !inactiveTabs.isEmpty else { return }
        /// Triggers once a given browser tab is fully loaded
        /// we are only interested in the first event
        task = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .browserTabLoaded) {
                self?.preload(inactiveTabs)
            }
        }
    }
    
    private func unsubscribe() {
        task?.cancel()
        task = nil
    }
    
    @MainActor deinit {
        unsubscribe()
    }
    
    private func preload(_ inactiveTabs: [NSManagedObjectID: UUID]) {
        // ignoring repeated notification events
        guard !isStarted else { return }
        isStarted = true
        unsubscribe()
        
        let zimFileIds = Set(inactiveTabs.values)
        let tabIDs = inactiveTabs.keys
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
        }
    }
}
#endif
