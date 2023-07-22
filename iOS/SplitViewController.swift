//
//  SplitViewController.swift
//  Kiwix
//
//  Created by Chris Li on 6/25/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

#if os(iOS)
import CoreData
import SwiftUI
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
        // attempt to open files
        urlContexts.forEach { context in
            guard context.url.isFileURL, let _ = ZimFileService.getMetaData(url: context.url) else { return }
            LibraryOperations.open(url: context.url)
        }
        
        // attempt to open article url
        guard let url = urlContexts.first?.url,
              !url.isFileURL,
              let splitViewController = window?.rootViewController as? SplitViewController else { return }
        Task { await splitViewController.createTab(url: url) }
    }
}

class SplitViewController: UISplitViewController {
    @MainActor private var browserViewModel = BrowserViewModel()
    @MainActor private var libraryViewModel = LibraryViewModel()
    @MainActor private(set) var selectedNavigationItem: NavigationItem?
    
    private var openURLNotificationObserver: AnyObject?
    
    convenience init() {
        self.init(style: .doubleColumn)
        
        setViewController(SidebarViewController(), for: .primary)
        setViewController(UITableViewController(), for: .secondary)
        
        let compactView = CompactView()
            .environmentObject(browserViewModel)
            .environmentObject(libraryViewModel)
            .environment(\.managedObjectContext, Database.viewContext)
        let compactViewController = CompactViewController(rootView: compactView)
        setViewController(UINavigationController(rootViewController: compactViewController), for: .compact)

        if #available(iOS 16.0, *) {} else {
            preferredSplitBehavior = .tile
        }
        
        openURLNotificationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.openURL, object: nil, queue: nil) { [unowned self] notification in
                presentedViewController?.dismiss(animated: true)
                guard let url = notification.userInfo?["url"] as? URL else { return }
                if case .tab = selectedNavigationItem {
                    browserViewModel.load(url: url)
                } else {
                    Task { await self.createTab(url: url) }
                }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load initial tab
        let initialNavigationItem = {
            let fetchRequest = Tab.fetchRequest(sortDescriptors: [NSSortDescriptor(key: "created", ascending: false)])
            let tab = (try? Database.viewContext.fetch(fetchRequest).first) ?? {
                let tab = Tab(context: Database.viewContext)
                tab.id = UUID()
                tab.created = Date()
                tab.lastOpened = Date()
                try? Database.viewContext.obtainPermanentIDs(for: [tab])
                try? Database.viewContext.save()
                return tab
            }()
            return NavigationItem.tab(objectID: tab.objectID)
        }()
        navigateTo(initialNavigationItem)
    }
    
    @MainActor
    func navigateTo(_ navigationItem: NavigationItem) {
        guard selectedNavigationItem != navigationItem else { return }
        selectedNavigationItem = navigationItem
        switch navigationItem {
        case .bookmarks:
            let view = Bookmarks().environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
        case .tab(let objectID):
            guard let tab = try? Database.viewContext.existingObject(with: objectID) as? Tab else { return }
            browserViewModel.prepareForTab(tab.id)
            let view = BrowserTab()
                .environmentObject(browserViewModel)
                .environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
            presentedViewController?.dismiss(animated: true)
        case .opened:
            libraryViewModel.selectedZimFile = nil
            let view = ZimFilesOpened()
                .environmentObject(libraryViewModel)
                .environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
        case .categories:
            libraryViewModel.selectedZimFile = nil
            let view = ZimFilesCategories()
                .environmentObject(libraryViewModel)
                .environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
        case .downloads:
            libraryViewModel.selectedZimFile = nil
            let view = ZimFilesDownloads()
                .environmentObject(libraryViewModel)
                .environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
        case .new:
            libraryViewModel.selectedZimFile = nil
            let view = ZimFilesNew()
                .environmentObject(libraryViewModel)
                .environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
        case .settings:
            let view = Settings()
                .environmentObject(libraryViewModel)
                .environment(\.managedObjectContext, Database.viewContext)
            let controller = UINavigationController(rootViewController: UIHostingController(rootView: view))
            setViewController(controller, for: .secondary)
        default:
            setViewController(UITableViewController(), for: .secondary)
        }
    }
    
    // MARK: - Tab Management
    
    private func makeTab(context: NSManagedObjectContext) -> Tab {
        let tab = Tab(context: context)
        tab.id = UUID()
        tab.created = Date()
        tab.lastOpened = Date()
        return tab
    }
    
    func createTab(url: URL? = nil) async {
        let objectID = await Database.performBackgroundTask { context in
            let tab = self.makeTab(context: context)
            try? context.obtainPermanentIDs(for: [tab])
            try? context.save()
            return tab.objectID
        }
        navigateTo(NavigationItem.tab(objectID: objectID))
        if let url {
            browserViewModel.load(url: url)
        }
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
