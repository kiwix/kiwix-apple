//
//  Reader.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

#if os(macOS)
struct Reader: View {
    @SceneStorage("Reader.SidebarDisplayMode") private var sidebarDisplayMode: SidebarDisplayMode = .search
    @StateObject var viewModel = ReaderViewModel()
    @State var url: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 6) {
                    Divider()
                    HStack(spacing: 20) {
                        ForEach(SidebarDisplayMode.allCases) { displayMode in
                            Button {
                                self.sidebarDisplayMode = displayMode
                            } label: {
                                Image(systemName: displayMode.imageName)
                                    .foregroundColor(self.sidebarDisplayMode == displayMode ? .blue : nil)
                            }
                            .buttonStyle(.borderless)
                            .help(displayMode.help)
                        }
                    }
                    Divider()
                }.background(.thinMaterial)
                switch sidebarDisplayMode {
                case .search:
                    Search(url: $url)
                case .bookmarks:
                    Bookmarks(url: $url)
                case .outline:
                    Outline()
                case .library:
                    ZimFilesOpened(url: $url)
                }
            }
            .frame(minWidth: 250)
            .toolbar { SidebarButton() }
            Group {
                if url == nil {
                    Welcome(url: $url)
                } else {
                    WebView(url: $url).ignoresSafeArea(edges: .all)
                }
            }
            .frame(minWidth: 400, idealWidth: 800, minHeight: 500, idealHeight: 550)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    ControlGroup {
                        NavigateBackButton()
                        NavigateForwardButton()
                    }
                }
                ToolbarItemGroup {
                    BookmarkButton(url: url)
                    MainArticleButton(url: $url)
                    RandomArticleButton(url: $url)
                }
            }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.readerViewModel, viewModel)
        .focusedSceneValue(\.sidebarDisplayMode, $sidebarDisplayMode)
        .navigationTitle(viewModel.articleTitle)
        .navigationSubtitle(viewModel.zimFileName)
    }
    
    struct ZimFilesOpened: View {
        @Binding var url: URL?
        @FetchRequest(
            sortDescriptors: [SortDescriptor(\ZimFile.size, order: .reverse)],
            predicate: NSPredicate(format: "fileURLBookmark != nil"),
            animation: .easeInOut
        ) private var zimFiles: FetchedResults<ZimFile>
        @State var selected: UUID?
        
        var body: some View {
            Group {
                if zimFiles.isEmpty {
                    Message(text: "No opened zim files").ignoresSafeArea(edges: .vertical)
                } else {
                    List(zimFiles, id: \.fileID, selection: $selected) { zimFile in
                        ZimFileRow(zimFile)
                    }
                    .onChange(of: selected) { zimFileID in
                        guard let zimFileID = zimFileID,
                              let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
                        self.url = url
                        selected = nil
                    }
                }
            }.safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Button {
                            
                        } label: { Image(systemName: "plus") }
                        Spacer()
                        Button {
                            
                        } label: { Image(systemName: "folder") }
                    }
                    .buttonStyle(.borderless)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }.background(.thinMaterial)
            }
        }
    }
}
#elseif os(iOS)
struct Reader: View {
    @Binding var isSearchActive: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject var viewModel = ReaderViewModel()
    @State private var sheetDisplayMode: SheetDisplayMode?
    @State private var sidebarDisplayMode: SidebarDisplayMode?
    @State private var url: URL?
    
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    if sidebarDisplayMode == .outline, horizontalSizeClass == .regular {
                        Outline().listStyle(.plain).frame(width: min(320, proxy.size.width * 0.35))
                        Divider()
                    } else if sidebarDisplayMode == .bookmarks, horizontalSizeClass == .regular {
                        Bookmarks(url: $url).listStyle(.plain).frame(width: min(320, proxy.size.width * 0.35))
                        Divider()
                    }
                }
                .transition(.opacity)
                .animation(Animation.easeInOut, value: sidebarDisplayMode)
                Group {
                    if url == nil {
                        Welcome(url: $url)
                    } else {
                        WebView(url: $url).ignoresSafeArea(.container, edges: .all)
                    }
                }
                .animation(Animation.easeInOut, value: sidebarDisplayMode)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular, !isSearchActive {
                    NavigateBackButton()
                    NavigateForwardButton()
                    OutlineButton(sheetDisplayMode: $sheetDisplayMode, sidebarDisplayMode: $sidebarDisplayMode)
                    BookmarkButton(
                        url: url, sheetDisplayMode: $sheetDisplayMode, sidebarDisplayMode: $sidebarDisplayMode
                    )
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isSearchActive {
                    Button("Cancel") {
                        withAnimation {
                            isSearchActive = false
                        }
                    }
                } else if horizontalSizeClass == .regular {
                    RandomArticleButton(url: $url)
                    MainArticleButton(url: $url)
                    Button { sheetDisplayMode = .library } label: { Image(systemName: "folder") }
                    Button { sheetDisplayMode = .settings } label: { Image(systemName: "gear") }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact, !isSearchActive {
                    Group {
                        NavigateBackButton()
                        Spacer()
                        NavigateForwardButton()
                        Spacer()
                        OutlineButton(sheetDisplayMode: $sheetDisplayMode, sidebarDisplayMode: $sidebarDisplayMode)
                        Spacer()
                        BookmarkButton(
                            url: url, sheetDisplayMode: $sheetDisplayMode, sidebarDisplayMode: $sidebarDisplayMode
                        )
                        Spacer()
                        RandomArticleButton(url: $url)
                    }
                    Spacer()
                    MoreButton(url: $url, sheetDisplayMode: $sheetDisplayMode)
                }
            }
        }
        .sheet(item: $sheetDisplayMode) { displayMode in
            switch displayMode {
            case .outline:
                OutlineSheet()
            case .bookmarks:
                BookmarksSheet(url: $url)
            case .library:
                Library()
            case .settings:
                Settings()
            }
        }
        .environmentObject(viewModel)
        .onChange(of: horizontalSizeClass) { _ in
            if sheetDisplayMode == .outline || sheetDisplayMode == .bookmarks {
                sheetDisplayMode = nil
            }
        }
        .onOpenURL { url in
            self.url = url
            withAnimation {
                isSearchActive = false
                sheetDisplayMode = nil
            }
        }
    }
}
#endif
