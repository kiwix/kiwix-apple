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
                    Button("load main page") { }
                } else {
                    WebView(url: $url).ignoresSafeArea(.container, edges: .all)
                }
            }
            .frame(minWidth: 400, idealWidth: 800, minHeight: 500, idealHeight: 550)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    NavigateBackButton()
                    NavigateForwardButton()
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
            if zimFiles.isEmpty {
                Message(text: "No opened zim files")
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
                if horizontalSizeClass == .regular, sidebarDisplayMode == .outline {
                    Outline().listStyle(.plain).frame(width: min(300, proxy.size.width * 0.35))
                    Divider().ignoresSafeArea(.all, edges: .bottom)
                }
                if horizontalSizeClass == .regular, sidebarDisplayMode == .bookmarks {
                    Bookmarks(url: $url).listStyle(.plain).frame(width: min(300, proxy.size.width * 0.35))
                    Divider().ignoresSafeArea(.all, edges: .bottom)
                }
                if url == nil {
                    List {
                        Text("Welcome!")
                        Text("Item 1")
                        Text("Item 2")
                        Text("Item 3")
                    }
                } else {
                    WebView(url: $url).ignoresSafeArea(.container, edges: .all)
                }
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
            default:
                EmptyView()
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
                sheetDisplayMode = nil
            }
        }
    }
}
#endif
