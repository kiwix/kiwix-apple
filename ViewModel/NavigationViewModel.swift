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
import WebKit
import Combine

@MainActor
final class NavigationViewModel: ObservableObject {
    let uuid = UUID()
    // remained optional due to focusedSceneValue conformance
    @Published var currentItem: NavigationItem? = .loading
    private(set) var showDownloads = PassthroughSubject<Void, Never>()
    
    private var openingFilesTask: Task<Void, Never>?
    
    #if os(macOS)
    var isTerminating: Bool = false
    
    /// Used to store temporarily the value of the tabID for a newly opened window
    static var tabIDToUseOnNewTab: NSManagedObjectID?

    var currentTabId: NSManagedObjectID {
        guard let currentTabIdValue else {
            let newTabId: NSManagedObjectID
            // when opening a new tab, use a preconfigured tabID
            if let tabIDToUseOnNewTab = Self.tabIDToUseOnNewTab {
                newTabId = tabIDToUseOnNewTab
                Self.tabIDToUseOnNewTab = nil
            } else {
                newTabId = createTab()
            }
            currentTabIdValue = newTabId
            return newTabId
        }
        return currentTabIdValue
    }

    private var currentTabIdValue: NSManagedObjectID?
    #endif

    // MARK: - Tab Management

    nonisolated static func makeTab(context: NSManagedObjectContext) -> Tab {
        let tab = Tab(context: context)
        tab.created = Date()
        tab.lastOpened = Date()
        try? context.obtainPermanentIDs(for: [tab])
        try? context.save()
        return tab
    }

    func navigateToMostRecentTab() {
        Task {
            await navigateToMostRecentTabAsync()
        }
    }

    private func navigateToMostRecentTabAsync() async {
        let fetchRequest = Tab.fetchRequestLastOpened()
        let context = Database.shared.viewContext
        let tab = (try? context.fetch(fetchRequest).first) ?? Self.makeTab(context: context)
        await MainActor.run { [weak self] in
            self?.currentItem = NavigationItem.tab(objectID: tab.objectID)
        }
    }

    @discardableResult
    func createTab() -> NSManagedObjectID {
        let context = Database.shared.viewContext
        let tab = Self.makeTab(context: context)
        #if !os(macOS)
        currentItem = NavigationItem.tab(objectID: tab.objectID)
        #endif
        return tab.objectID
    }

    @MainActor
    func tabIDFor(url: URL?) -> NSManagedObjectID {
        guard let url,
              let coordinator = Database.shared.viewContext.persistentStoreCoordinator,
              let tabID = coordinator.managedObjectID(forURIRepresentation: url),
              // make sure it's not went missing
              let tab = try? Database.shared.viewContext.existingObject(with: tabID) as? Tab,
              tab.zimFile != nil
        else {
            return createTab()
        }
        return tabID
    }
    
    func deleteTabsWithMissingZimFiles() async {
        let tabIDsToClose: [NSManagedObjectID] = await Database.shared.viewContext.perform {
            let predicate = Tab.Predicate.zimFileMissing()
            let context = Database.shared.viewContext
            var tabIDsToClose: [NSManagedObjectID] = []
            let tabsRequest = Tab.fetchRequest(predicate: predicate)
            guard let tabs = try? context.fetch(tabsRequest), !tabs.isEmpty else {
                return []
            }
            for tab in tabs {
                tabIDsToClose.append(tab.objectID)
                context.delete(tab)
                // destroy the BrowserViewModel
            }
            if context.hasChanges {
                try? context.save()
            }
            return tabIDsToClose
        }
        for tabID in tabIDsToClose {
            BrowserViewModel.destroyTabById(id: tabID)
        }
        print("NavigationViewModel.deleteTabs by: \(tabIDsToClose)")
        // if the currently selected tab was deleted
        if case let .tab(tabID) = currentItem, tabIDsToClose.contains(tabID) {
            await navigateToMostRecentTabAsync()
        }
    }

    /// Delete a single tab, and select another tab
    /// Note: do not use in a loop to delete more than 1 tab
    /// - Parameter tabID: ID of the tab to delete
    func deleteTab(tabID: NSManagedObjectID) async {
        let currentItemValue = currentItem
        let newTabId: NSManagedObjectID? = await Database.shared.viewContext.perform {
            let context = Database.shared.viewContext
            let sortByCreation = [NSSortDescriptor(key: "created", ascending: false)]
            guard let tabs: [Tab] = try? context.fetch(Tab.fetchRequest(predicate: Tab.Predicate.notMissing(),
                                                                        sortDescriptors: sortByCreation)),
                  let tab: Tab = tabs.first(where: { $0.objectID == tabID }) else {
                return nil
            }
            let newlySelectedTab: Tab?
            if case let .tab(selectedTabID) = currentItemValue, selectedTabID == tabID {
                // select a closeBy tab if the currently selected tab is to be deleted
                newlySelectedTab = tabs.closeBy(toWhere: { $0.objectID == tabID }) ?? Self.makeTab(context: context)
            } else if tabs.count == 1 {
                // we are deleting the last tab and the selection is somewhere else
                newlySelectedTab = Self.makeTab(context: context)
            } else {
                newlySelectedTab = nil // the current selection should remain
            }
            // delete tab
            context.delete(tab)
            try? context.save()
            
            return newlySelectedTab?.objectID
        }
            
        // destroy the BrowserViewModel
        BrowserViewModel.destroyTabById(id: tabID)

        // update selection if needed
        if let newTabId {
            currentItem = NavigationItem.tab(objectID: newTabId)
        }
    }

    /// Delete all tabs, and open a new tab
    func deleteAllTabs() async {
        let tabIdsToDelete = await Database.shared.viewContext.perform {
            let context = Database.shared.viewContext
            // delete all existing tabs
            let tabs = try? context.fetch(Tab.fetchRequest())
            var tabIds: [NSManagedObjectID] = []
            tabs?.forEach {
                tabIds.append($0.objectID)
                context.delete($0)
            }
            try? context.save()
            return tabIds
        }
        for tabId in tabIdsToDelete {
            // destroy the BrowserViewModel
            BrowserViewModel.destroyTabById(id: tabId)
        }
        // create new tab via navigateToMostRecent fallback
        await navigateToMostRecentTabAsync()
    }

    #if os(macOS)
    /// On closing a ZIM, this clears out the currentTabId if needed
    /// Effectively recreating BrowserViewModel and the wkwebview
    /// from scratch
    /// - Parameter tabIds: the ones that should remain
    func keepOnlyTabsBy(tabIds: Set<NSManagedObjectID>) {
        guard let currentId = currentTabIdValue,
              !tabIds.contains(currentId) else {
            return
        }
        // setting it to nil ensures a new tab (and webview) will be created
        // on accessing the public currentTabId
        currentTabIdValue = nil
    }
    #endif
    
    #if os(iOS)
    func observeOpeningFiles() {
        openingFilesTask = Task {
            // open main page or open in new tab via long tap
            for await notification in NotificationCenter.default.notifications(named: .openURL) {
                guard let url = notification.userInfo?["url"] as? URL else { return }
                let inNewTab = notification.userInfo?["inNewTab"] as? Bool ?? false
                let deepLinkId: UUID?
                if case .deepLink(.some(let linkID)) = notification.userInfo?["context"] as? OpenURLContext {
                    deepLinkId = linkID
                } else {
                    deepLinkId = nil
                }
                Task { @MainActor in
                    if !inNewTab, case let .tab(tabID) = currentItem {
                        BrowserViewModel.getCached(tabID: tabID).load(url: url)
                    } else {
                        let tabID = createTab()
                        BrowserViewModel.getCached(tabID: tabID).load(url: url)
                    }
                    if let deepLinkId {
                        DeepLinkService.shared.stopFor(uuid: deepLinkId)
                    }
                }
            }
        }
    }
    #endif
}

extension Array {

    /// Return an element close to the one defined in the where callback,
    /// either the one before or if this is the first, the one after
    /// - Parameter toWhere: similar role as in find(where: ) closure, this element is never returned
    /// - Returns: the element before or the one after, never the one that matches by toWhere:
    func closeBy(toWhere whereCallback: @escaping (Element) -> Bool) -> Element? {
        var previous: Element?
        var returnNext: Bool = false
        for element in self {
            if returnNext {
                return element
            }
            if whereCallback(element) {
                if let previous {
                    return previous
                } else {
                    returnNext = true
                }
            } else {
                previous = element
            }
        }
        return previous
    }
}
