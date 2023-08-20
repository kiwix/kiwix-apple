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
    func createTab() -> NSManagedObjectID{
        let context = Database.viewContext
        let tab = self.makeTab(context: context)
        try? context.obtainPermanentIDs(for: [tab])
        try? context.save()
        currentItem = NavigationItem.tab(objectID: tab.objectID)
        return tab.objectID
    }
    
    /// Delete a single tab, and select another tab
    /// - Parameter tabID: ID of the tab to delete
    func deleteTab(tabID: NSManagedObjectID) async {
        let deletedTabCreatedAt: Date? = await Database.performBackgroundTask { context in
            defer { try? context.save() }
            guard let tab = try? context.existingObject(with: tabID) as? Tab else { return nil }
            context.delete(tab)
            return tab.created
        }
//        webViews.removeValue(forKey: tabID)
        
        // wait for a bit to avoid broken sidebar animation
        try? await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
        
        // select a new tab if current tab is deleted
        guard case let .tab(selectedTabID) = self.currentItem,
              selectedTabID == tabID,
              let deletedTabCreatedAt else { return }
        let tabID = await Database.performBackgroundTask { context in
            let fetchRequest = Tab.fetchRequest(
                predicate: NSPredicate(format: "created < %@", deletedTabCreatedAt as CVarArg),
                sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)]
            )
            fetchRequest.fetchLimit = 1
            let newTab = (try? context.fetch(fetchRequest).first) ?? self.makeTab(context: context)
            try? context.obtainPermanentIDs(for: [newTab])
            try? context.save()
            return newTab.objectID
        }
        currentItem = NavigationItem.tab(objectID: tabID)
    }
    
    /// Delete all tabs, and open a new tab
    func deleteAllTabs() async {
        await Database.performBackgroundTask { context in
            let tabs = try? context.fetch(Tab.fetchRequest())
            tabs?.forEach { context.delete($0) }
            try? context.save()
        }
//        webViews.removeAll()
        
        // wait for a bit to avoid broken sidebar animation
        try? await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
        
        // create a new tab
        currentItem = NavigationItem.tab(objectID: createTab())
    }
}

class WebViewCache {
    static let shared = WebViewCache()
    
    private var webViews = [NSManagedObjectID: WKWebView]()
    private(set) lazy var webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
    
    private init() { }
    
    func getWebView(tabID: NSManagedObjectID) -> WKWebView {
        if let webView = webViews[tabID] {
            return webView
        } else {
            let webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
            if let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab {
                webView.interactionState = tab.interactionState
            }
            webViews[tabID] = webView
            return webView
        }
    }
    
    func persistStates() {
        webViews.forEach { tabID, webView in
            guard let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else { return }
            tab.interactionState = webView.interactionState as? Data
        }
        try? Database.viewContext.save()
    }
}
