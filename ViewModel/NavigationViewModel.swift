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

@MainActor
final class NavigationViewModel: ObservableObject {
    let uuid = UUID()
    // remained optional due to focusedSceneValue conformance
    @Published var currentItem: NavigationItem? = .loading {
        didSet {
            debugPrint("NavigationViewModel.currentItem: \(currentItem)")
        }
    }
    #if os(macOS)
    var isTerminating: Bool = false
    var currentTabId: NSManagedObjectID {
        guard let currentTabIdValue else {
            let newTabId = createTab()
            currentTabIdValue = newTabId
            return newTabId
        }
        return currentTabIdValue
    }

    private var currentTabIdValue: NSManagedObjectID?
    #endif

    init() {
        debugPrint("NavigationViewModel init()")
    }

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
        let context = Database.shared.viewContext
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
        let context = Database.shared.viewContext
        let tab = self.makeTab(context: context)
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

    /// Delete a single tab, and select another tab
    /// - Parameter tabID: ID of the tab to delete
    func deleteTab(tabID: NSManagedObjectID) {
        Database.shared.performBackgroundTask { context in
            let sortByCreation = [NSSortDescriptor(key: "created", ascending: false)]
            guard let tabs: [Tab] = try? context.fetch(Tab.fetchRequest(predicate: nil,
                                                                        sortDescriptors: sortByCreation)),
                  let tab: Tab = tabs.first(where: { $0.objectID == tabID }) else {
                return
            }
            let newlySelectedTab: Tab?
            if case let .tab(selectedTabID) = self.currentItem, selectedTabID == tabID {
                // select a closeBy tab if the currently selected tab is to be deleted
                newlySelectedTab = tabs.closeBy(toWhere: { $0.objectID == tabID }) ?? self.makeTab(context: context)
            } else if tabs.count == 1 {
                // we are deleting the last tab and the selection is somewhere else
                newlySelectedTab = self.makeTab(context: context)
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
        Database.shared.performBackgroundTask { context in
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
