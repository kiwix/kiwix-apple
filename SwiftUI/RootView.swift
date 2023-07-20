//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var url: URL?
    @StateObject private var viewModel = ViewModel()
    @StateObject private var readingViewModel = ReadingViewModel()
    @StateObject private var browserViewModel = BrowserViewModel()
    
    private let primaryItems: [NavigationItem] =
        FeatureFlags.map ? [.reading, .bookmarks, .map(location: nil)] : [.reading, .bookmarks]
    private let libraryItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    private let openURLNotification = NotificationCenter.default.publisher(for: Notification.Name.openURL)
    
    var body: some View {
        NavigationView {
            List(selection: $viewModel.navigationItem) {
                ForEach(primaryItems, id: \.self) { navigationItem in
                    Label(navigationItem.name, systemImage: navigationItem.icon)
                }
                Section("Library") {
                    ForEach(libraryItems, id: \.self) { navigationItem in
                        Label(navigationItem.name, systemImage: navigationItem.icon)
                    }
                }
            }.frame(minWidth: 150).toolbar { SidebarButton() }
            Group {
                switch viewModel.navigationItem {
                case .reading:
                    BrowserTab().environmentObject(browserViewModel)
                case .bookmarks:
                    Bookmarks()
                case .map(let location):
                    Map(location: location)
                case .opened:
                    ZimFilesOpened().modifier(LibraryZimFileDetailSidePanel())
                case .categories:
                    ZimFilesCategories().modifier(LibraryZimFileDetailSidePanel())
                case .downloads:
                    ZimFilesDownloads().modifier(LibraryZimFileDetailSidePanel())
                case .new:
                    ZimFilesNew().modifier(LibraryZimFileDetailSidePanel())
                default:
                    EmptyView()
                }
            }.frame(minWidth: 500, minHeight: 500)
        }
        .navigationViewStyle(.columns)
        .focusedSceneValue(\.navigationItem, $viewModel.navigationItem)
        .focusedSceneValue(\.url, url)
        .alert(item: $viewModel.activeAlert) { activeAlert in
            switch activeAlert {
            case .articleFailedToLoad:
                return Alert(
                    title: Text("Unable to Load Article"),
                    message: Text(
                        "The zim file associated with the article might be missing or the link might be corrupted."
                    )
                )
            case .externalLinkAsk(let url):
                return Alert(
                    title: Text("External Link"),
                    message: Text("An external link is tapped, do you wish to load the link?"),
                    primaryButton: .default(Text("Load the link")) {
                        #if os(macOS)
                        NSWorkspace.shared.open(url)
                        #elseif os(iOS)
                        viewModel.activeSheet = .safari(url: url)
                        #endif
                    },
                    secondaryButton: .cancel()
                )
            case .externalLinkNotLoading:
                return Alert(
                    title: Text("External Link"),
                    message: Text(
                        "An external link is tapped. However, your current setting does not allow it to be loaded."
                    )
                )
            }
        }
        .onChange(of: url) { _ in
            viewModel.navigationItem = .reading
            viewModel.activeSheet = nil
        }
        .onChange(of: horizontalSizeClass) { _ in
            viewModel.navigationItem = .reading
            viewModel.activeSheet = nil
        }
        .onOpenURL { url in
            if url.isFileURL {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                LibraryOperations.open(url: url)
                self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
            } else if url.scheme == "kiwix" {
                self.url = url
            }
        }
        .onReceive(openURLNotification) { notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            browserViewModel.load(url: url)
            viewModel.navigationItem = .reading
        }
        .environmentObject(viewModel)
        .environmentObject(readingViewModel)
    }
}
#endif
