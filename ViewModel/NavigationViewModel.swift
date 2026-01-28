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

    private func navigateToMostRecentTabAsync(
        using context: NSManagedObjectContext = Database.shared.viewContext
    ) async {
        let fetchRequest = Tab.fetchRequestLastOpened()
        let tab = (try? context.fetch(fetchRequest).first) ?? Self.makeTab(context: context)
        await MainActor.run { [weak self] in // is switching to MainActor needed ?
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
        let context = Database.shared.backgroundContext
        let closedTabIDs: [NSManagedObjectID] = await context.perform {
            var tabIDsToClose: [NSManagedObjectID] = []
            let tabsRequest = Tab.fetchRequest(predicate: Tab.Predicate.zimFileMissing)
            guard let tabs = try? tabsRequest.execute(), !tabs.isEmpty else {
                return []
            }
            for tab in tabs {
                tabIDsToClose.append(tab.objectID)
                context.delete(tab)
            }
            try? context.save()
            return tabIDsToClose
        }
        for tabID in closedTabIDs {
            // destroy the BrowserViewModel
            await BrowserViewModel.destroyTabById(id: tabID)
        }
        print("NavigationViewModel.deleteTabs by: \(closedTabIDs)")
        
        // if the currently selected tab was deleted
        if case let .tab(tabID) = currentItem, closedTabIDs.contains(tabID) {
            await navigateToMostRecentTabAsync(using: context)
        }
    }

    /// Delete a single tab, and select another tab
    /// Note: do not use in a loop to delete more than 1 tab
    /// - Parameter tabID: ID of the tab to delete
    func deleteTab(tabID: NSManagedObjectID) async {
        let currentItemValue = currentItem
        let context = Database.shared.backgroundContext
        let newlySelectedId: NSManagedObjectID? = await context.perform {
            let sortByCreation = [NSSortDescriptor(key: "created", ascending: false)]
            let fetchRequest = Tab.fetchRequest(predicate: Tab.Predicate.notMissing,
                                                sortDescriptors: sortByCreation)
            guard let tabs: [Tab] = try? fetchRequest.execute(),
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
            // return the selection update if any
            return newlySelectedTab?.objectID
        }
        
        // destroy the BrowserViewModel
        await BrowserViewModel.destroyTabById(id: tabID)
        
        if let newlySelectedId {
            // update the selection
            self.currentItem = NavigationItem.tab(objectID: newlySelectedId)
        }
    }

    /// Delete all tabs, and open a new tab
    nonisolated func deleteAllTabs() async {
        let context = Database.shared.backgroundContext
        let tabIDs = try? await context.perform {
            let request = Tab.fetchRequest()
            let tabs = try request.execute()
            let tabIDs = tabs.map{ $0.objectID }
            tabs.forEach { tab in
                context.delete(tab)
            }
            try context.save()
            return tabIDs
        }
        guard let tabIDs else {
            return
        }
        await navigateToMostRecentTabAsync()
        
        // destroy the BrowserViewModel
        for tabID in tabIDs {
            await BrowserViewModel.destroyTabById(id: tabID)
        }
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
