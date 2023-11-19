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
    @Published var currentItem: NavigationItem?
    @Published var readingURL: URL?

    init() {
        #if os(macOS)
        currentItem = .reading
        #elseif os(iOS)
        navigateToMostRecentTab()
        #endif
    }
    
    // MARK: - Tab Management
    
    private func makeTab(context: NSManagedObjectContext) -> Tab {
        let tab = Tab(context: context)
        tab.created = Date()
        tab.lastOpened = Date()
        return tab
    }
    
    func navigateToMostRecentTab() {
        let context = Database.viewContext
        let fetchRequest = Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "lastOpened", ascending: false)])
        fetchRequest.fetchLimit = 1
        let tab = (try? context.fetch(fetchRequest).first) ?? self.makeTab(context: context)
        try? context.obtainPermanentIDs(for: [tab])
        try? context.save()
        currentItem = NavigationItem.tab(objectID: tab.objectID)
    }
    
    @discardableResult
    func createTab() -> NSManagedObjectID {
        let context = Database.viewContext
        let tab = self.makeTab(context: context)
        try? context.obtainPermanentIDs(for: [tab])
        try? context.save()
        #if !os(macOS)
        currentItem = NavigationItem.tab(objectID: tab.objectID)
        #endif
        return tab.objectID
    }

    @MainActor
    func tabIDFor(url: URL?) -> NSManagedObjectID {
        guard let url else {
            return createTab()
        }
        let coordinator = Database.viewContext.persistentStoreCoordinator
        guard let tabID = coordinator?.managedObjectID(forURIRepresentation: url) else {
            return createTab()
        }
        return tabID
    }

    /// Delete a single tab, and select another tab
    /// - Parameter tabID: ID of the tab to delete
    func deleteTab(tabID: NSManagedObjectID) {
        Database.performBackgroundTask { context in
            guard let tab = try? context.existingObject(with: tabID) as? Tab else { return }
            
            // select a new tab if the currently selected tab is being deleted
            if case let .tab(selectedTabID) = self.currentItem, selectedTabID == tabID {
                let fetchRequest = Tab.fetchRequest(
                    predicate: NSPredicate(format: "created < %@", tab.created as CVarArg),
                    sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)]
                )
                fetchRequest.fetchLimit = 1
                let newTab = (try? context.fetch(fetchRequest).first) ?? self.makeTab(context: context)
                try? context.obtainPermanentIDs(for: [newTab])
                DispatchQueue.main.async {
                    self.currentItem = NavigationItem.tab(objectID: newTab.objectID)
                }
            }
            
            // delete tab
            context.delete(tab)
            try? context.save()
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
            try? context.obtainPermanentIDs(for: [newTab])
            DispatchQueue.main.async {
                self.currentItem = NavigationItem.tab(objectID: newTab.objectID)
            }
            
            try? context.save()
        }
    }
}
