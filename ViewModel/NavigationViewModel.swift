//
//  NavigationViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 7/29/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import WebKit

@MainActor
class NavigationViewModel: ObservableObject {
    // remained optional due to focusedSceneValue conformance
    @Published var currentItem: NavigationItem? = .loading

    // MARK: - Tab Management
    
    private func makeTab(context: NSManagedObjectContext) -> Tab {
        let tab = Tab(context: context)
        tab.created = Date()
        tab.lastOpened = Date()
        try? context.obtainPermanentIDs(for: [tab])
        try? context.save()
        return tab
    }
    
    func navigateToMostRecentTab() {
        let context = Database.viewContext
        let fetchRequest = Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "lastOpened", ascending: false)])
        fetchRequest.fetchLimit = 1
        let tab = (try? context.fetch(fetchRequest).first) ?? self.makeTab(context: context)
        Task {
            await MainActor.run {
                currentItem = NavigationItem.tab(objectID: tab.objectID)
            }
        }

    }
    
    @discardableResult
    func createTab() -> NSManagedObjectID {
        let context = Database.viewContext
        let tab = self.makeTab(context: context)
        #if !os(macOS)
        currentItem = NavigationItem.tab(objectID: tab.objectID)
        #endif
        return tab.objectID
    }

    @MainActor
    func tabIDFor(url: URL?) -> NSManagedObjectID {
        guard let url,
              let coordinator = Database.viewContext.persistentStoreCoordinator,
              let tabID = coordinator.managedObjectID(forURIRepresentation: url) else {
            return createTab()
        }
        return tabID
    }

    /// Delete a single tab, and select another tab
    /// - Parameter tabID: ID of the tab to delete
    func deleteTab(tabID: NSManagedObjectID) {
        Database.performBackgroundTask { context in
            guard let tabs: [Tab] = try? context.fetch(Tab.fetchRequest()),
                  let tab: Tab = tabs.first(where: { $0.objectID == tabID }) else {
                return
            }
            let newlySelectedTab: Tab?
            // select a closeBy tab if the currently selected tab is to be deleted
            if case let .tab(selectedTabID) = self.currentItem, selectedTabID == tabID {
                newlySelectedTab = tabs.closeBy(toWhere: { $0.objectID == tabID }) ?? self.makeTab(context: context)
            } else {
                newlySelectedTab = nil // the current selection should remain
            }

            // delete tab
            context.delete(tab)
            try? context.save()

            // update selection if needed
            if let newlySelectedTab {
                Task {
                    await MainActor.run {
                        self.currentItem = NavigationItem.tab(objectID: newlySelectedTab.objectID)
                    }
                }
            }
        }
    }
    
    /// Delete all tabs, and open a new tab
    func deleteAllTabs() {
        Database.performBackgroundTask { context in
            // delete all existing tabs
            let tabs = try? context.fetch(Tab.fetchRequest())
            tabs?.forEach { context.delete($0) }
            
            // create new tab
            let newTab = self.makeTab(context: context)
            Task {
                await MainActor.run {
                    self.currentItem = NavigationItem.tab(objectID: newTab.objectID)
                }
            }
        }
    }
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
