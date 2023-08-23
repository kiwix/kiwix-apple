//
//  LegacyView.swift
//  Kiwix
//
//  Created by Chris Li on 8/3/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
struct LegacyView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var navigation: NavigationViewModel
    @EnvironmentObject private var search: SearchViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var presentedSheet: PresentedSheet?
    @StateObject private var browser = BrowserViewModel()
    
    enum PresentedSheet: String, Identifiable {
        var id: String { rawValue }
        case library, settings
    }
    
    var body: some View {
        Group {
            if search.isSearching {
                SearchResults()
            } else if browser.url == nil {
                Welcome()
            } else {
                WebView().ignoresSafeArea()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular, !search.isSearching {
                    NavigationButtons()
                    OutlineButton()
                    BookmarkButton()
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular, !search.isSearching {
                    RandomArticleButton()
                    MainArticleButton()
                    Button {
                        presentedSheet = .library
                    } label: {
                        Label("Library", systemImage: "folder")
                    }
                    Button {
                        presentedSheet = .settings
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                } else if search.isSearching {
                    Button("Cancel") {
                        search.isSearching = false
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact, !search.isSearching {
                    NavigationButtons()
                    Spacer()
                    OutlineButton()
                    Spacer()
                    BookmarkButton()
                    Spacer()
                    RandomArticleButton()
                    Spacer()
                    Menu {
                        Section {
                            ForEach(zimFiles) { zimFile in
                                Button {
                                    guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.id) else { return }
                                    browser.load(url: url)
                                } label: {
                                    Label(zimFile.name, systemImage: "house")
                                }
                            }
                        }
                        Button {
                            presentedSheet = .library
                        } label: {
                            Label("Library", systemImage: "folder")
                        }
                        Button {
                            presentedSheet = .settings
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Label("More Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .environmentObject(browser)
        .focusedSceneValue(\.browserViewModel, browser)
        .focusedSceneValue(\.canGoBack, browser.canGoBack)
        .focusedSceneValue(\.canGoForward, browser.canGoForward)
        .onChange(of: browser.url) { _ in
            search.isSearching = false
            presentedSheet = nil
        }
        .sheet(item: $presentedSheet) { presentedSheet in
            switch presentedSheet {
            case .library:
                Library()
            case .settings:
                SheetContent { Settings() }
            }
        }
    }
}
#endif
