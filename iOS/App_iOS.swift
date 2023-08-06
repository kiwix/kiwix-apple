//
//  App_iOS.swift
//  Kiwix
//
//  Created by Chris Li on 7/27/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
@main
struct Kiwix: App {
    static let zimFileType = UTType(exportedAs: "org.openzim.zim")
    private let fileMonitor: DirectoryMonitor
    
    init() {
        fileMonitor = DirectoryMonitor(url: URL.documentDirectory) { LibraryOperations.scanDirectory($0) }
        LibraryOperations.reopen()
        LibraryOperations.scanDirectory(URL.documentDirectory)
        LibraryOperations.applyFileBackupSetting()
        LibraryOperations.registerBackgroundTask()
        LibraryOperations.applyLibraryAutoRefreshSetting()
        DownloadService.shared.restartHeartbeatIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView().environment(\.managedObjectContext, Database.viewContext)
        }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library = LibraryViewModel()
    @StateObject private var navigation = NavigationViewModel()
    
    private let primaryItems: [NavigationItem] = [.bookmarks, .settings]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    private let openURL = NotificationCenter.default.publisher(for: .openURL)
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                if horizontalSizeClass == .regular {
                    NavigationSplitView {
                        sidebar
                    } detail: {
                        content
                    }
                } else {
                    CompactView().ignoresSafeArea().onAppear() {
                        navigation.navigateToMostRecentTab()
                    }
                }
            } else {
                LegacyView().ignoresSafeArea()
            }
        }
        .environmentObject(library)
        .environmentObject(navigation)
        .onChange(of: scenePhase) { newScenePhase in
            guard newScenePhase == .inactive else { return }
            navigation.persistWebViewStates()
        }
        .onOpenURL { url in
            NotificationCenter.default.post(
                name: Notification.Name.openURL, object: nil, userInfo: ["url": url]
            )
        }
        .onReceive(openURL) { notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            if #available(iOS 16.0, *) {
                if case let .tab(tabID) = navigation.currentItem {
                    navigation.getWebView(tabID: tabID).load(URLRequest(url: url))
                } else {
                    let tabID = navigation.createTab()
                    navigation.getWebView(tabID: tabID).load(URLRequest(url: url))
                }
            } else {
                navigation.webView.load(URLRequest(url: url))
            }
        }
    }
    
    @available(iOS 16.0, *)
    private var sidebar: some View {
        List(selection: $navigation.currentItem) {
            ForEach(primaryItems, id: \.self) { navigationItem in
                Label(navigationItem.name, systemImage: navigationItem.icon)
            }
            Section("Tabs") {
                TabsSectionContent()
            }
            Section("Library") {
                ForEach(libraryItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
            }
        }
        .navigationTitle("Kiwix")
        .toolbar { NewTabButton() }
    }
    
    @ViewBuilder
    @available(iOS 16.0, *)
    private var content: some View {
        switch navigation.currentItem {
        case .bookmarks:
            Bookmarks()
        case .settings:
            Settings()
        case .tab(let tabID):
            BrowserTabRegular(tabID: tabID).id(tabID)
        case .opened:
            ZimFilesOpened()
        case .categories:
            ZimFilesCategories()
        case .downloads:
            ZimFilesDownloads()
        case .new:
            ZimFilesNew()
        default:
            EmptyView()
        }
    }
}
#endif
