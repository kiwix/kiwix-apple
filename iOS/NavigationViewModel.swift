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
    
    // for iOS 15 & above, where one scene supports multiple web views
    private var webViews = [NSManagedObjectID: WKWebView]()
    
    // for iOS 15 & below, and macOS, where one scene supports one web view
    private(set) lazy var webView = WKWebView(frame: .zero, configuration: WebViewConfiguration())
    
    init() {
        navigateToMostRecentTab()
    }
    
    // MARK: - Tab Management
    
    private func makeTab(context: NSManagedObjectContext) -> Tab {
        let tab = Tab(context: context)
        tab.id = UUID()
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
    
    func updateTab(tabID: NSManagedObjectID, lastOpened: Date) {
        guard let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else { return }
        tab.lastOpened = lastOpened
        try? Database.viewContext.save()
    }
    
    func deleteTab(objectID: NSManagedObjectID) async {
        let objectID: NSManagedObjectID? = await Database.performBackgroundTask { context in
            defer { try? context.save() }
            guard let tabToDelete = try? context.existingObject(with: objectID) as? Tab else { return nil }
            context.delete(tabToDelete)
            
            // select a new tab if selected tab is deleted
            guard case let .tab(selectedObjectID) = self.currentItem,
                  selectedObjectID == tabToDelete.objectID else {
                return nil
            }
            let fetchRequest = Tab.fetchRequest(
                predicate: NSPredicate(format: "created < %@", tabToDelete.created as CVarArg),
                sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)]
            )
            fetchRequest.fetchLimit = 1
            let newTab = (try? context.fetch(fetchRequest).first) ?? self.makeTab(context: context)
            try? context.obtainPermanentIDs(for: [newTab])
            return newTab.objectID
        }
        
        guard let objectID else { return }
        currentItem = NavigationItem.tab(objectID: objectID)
    }
    
    func deleteAllTabs() async {
        let objectID = await Database.performBackgroundTask { context in
            let tabs = try? context.fetch(Tab.fetchRequest())
            tabs?.forEach { context.delete($0) }
            let newTab = self.makeTab(context: context)
            try? context.save()
            return newTab.objectID
        }
        currentItem = NavigationItem.tab(objectID: objectID)
    }
    
    // MARK: - Web View Management
    
    func getWebView(tabID: NSManagedObjectID) -> WKWebView {
        let webView = webViews[tabID] ?? WKWebView(frame: .zero, configuration: WebViewConfiguration())
        if webView.url == nil, let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab {
            webView.interactionState = tab.interactionState
        }
        webViews[tabID] = webView
        return webView
    }
    
    func persistWebViewStates() {
        webViews.forEach { tabID, webView in
            guard let tab = try? Database.viewContext.existingObject(with: tabID) as? Tab else { return }
            tab.interactionState = webView.interactionState as? Data
        }
        try? Database.viewContext.save()
    }
}
