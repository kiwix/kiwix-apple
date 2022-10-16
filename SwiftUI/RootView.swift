//
//  RootView.swift
//  Kiwix
//
//  Created by Chris Li on 8/5/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var url: URL?
    @StateObject private var viewModel = ViewModel()
    @StateObject private var readingViewModel = ReadingViewModel()
    @StateObject private var libraryViewModel = LibraryViewModel()
    
    private let primaryNavigationItems: [NavigationItem] = [.reading, .bookmarks]
    private let libraryNavigationItems: [NavigationItem] = [.opened, .categories, .downloads, .new]
    
    var body: some View {
        Group {
            #if os(macOS)
            RootViewV2(url: $url)
            #elseif os(iOS)
            RootViewV1(url: $url).ignoresSafeArea(.all)
            #endif
        }
        #if os(iOS)
        .sheet(item: $viewModel.activeSheet) { activeSheet in
            switch activeSheet {
            case .outline:
                SheetContent {
                    OutlineTree().listStyle(.plain).navigationBarTitleDisplayMode(.inline)
                }.modify { view in
                    if #available(iOS 16.0, *) {
                        view.presentationDetents([.medium, .large])
                    }
                }
            case .bookmarks:
                SheetContent { BookmarksView(url: $url) }
            case .library(let navigationItem):
                Library(url: $url, navigationItem: navigationItem)
            case .settings:
                SheetContent { SettingsContent() }
            case .safari(let url):
                SafariView(url: url)
            }
        }
        #endif
        .modify { view in
            if #available(macOS 12.0, iOS 15.0, *) {
                view
                    .focusedSceneValue(\.navigationItem, $viewModel.navigationItem)
                    .focusedSceneValue(\.url, url)
            } else {
                view
            }
        }
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
        .environmentObject(viewModel)
        .environmentObject(readingViewModel)
        .environmentObject(libraryViewModel)
    }
}
