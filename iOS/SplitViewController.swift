//
//  SplitViewController.swift
//  Kiwix
//
//  Created by Chris Li on 6/25/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import CoreData
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = Database.viewContext  // load persistent stores
        LibraryOperations.reopen()
        LibraryOperations.scanDirectory(URL.documentDirectory)
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = SplitViewController()
        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        urlContexts.forEach { context in
            if context.url.isFileURL {
                guard let _ = ZimFileService.getMetaData(url: context.url) else { return }
                LibraryOperations.open(url: context.url)
            }
        }
    }
}

class SplitViewController: UISplitViewController {
    @MainActor private(set) var selectedNavigationItem: NavigationItem = {
        let fetchRequest = Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)])
        let tab = (try? Database.viewContext.fetch(fetchRequest).first) ?? {
            let tab = Tab(context: Database.viewContext)
            tab.id = UUID()
            tab.created = Date()
            tab.lastOpened = Date()
            try? Database.viewContext.save()
            return tab
        }()
        return NavigationItem.tab(objectID: tab.objectID)
    }()
    
    convenience init() {
        self.init(style: .doubleColumn)
        
        setViewController(SidebarViewController(), for: .primary)
        setViewController(UITableViewController(), for: .secondary)
        
        let compactViewController = CompactViewController(rootView: CompactView())
        setViewController(UINavigationController(rootViewController: compactViewController), for: .compact)
        
        if #available(iOS 16.0, *) {} else {
            preferredSplitBehavior = .tile
        }
    }
    
    @MainActor
    func navigateTo(_ navigationItem: NavigationItem) {
        selectedNavigationItem = navigationItem
    }
    
    // MARK: - Tab Management
    
    private func makeTab(context: NSManagedObjectContext) -> Tab {
        let tab = Tab(context: context)
        tab.id = UUID()
        tab.created = Date()
        tab.lastOpened = Date()
        return tab
    }
    
    func createTab() async {
        let objectID = await Database.performBackgroundTask { context in
            let tab = self.makeTab(context: context)
            try? context.obtainPermanentIDs(for: [tab])
            try? context.save()
            return tab.objectID
        }
        navigateTo(NavigationItem.tab(objectID: objectID))
    }
    
    func deleteTab(objectID: NSManagedObjectID) async {
        let objectID: NSManagedObjectID? = await Database.performBackgroundTask { context in
            defer { try? context.save() }
            guard let tabToDelete = try? context.existingObject(with: objectID) as? Tab else { return nil }
            context.delete(tabToDelete)
            
            // select a new tab if selected tab is deleted
            guard case let .tab(selectedObjectID) = self.selectedNavigationItem,
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
        navigateTo(NavigationItem.tab(objectID: objectID))
    }
    
    func deleteAllTabs() async {
        let objectID = await Database.performBackgroundTask { context in
            let tabs = try? context.fetch(Tab.fetchRequest())
            tabs?.forEach { context.delete($0) }
            let newTab = self.makeTab(context: context)
            try? context.save()
            return newTab.objectID
        }
        navigateTo(NavigationItem.tab(objectID: objectID))
    }
}
#endif
