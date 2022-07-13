//
//  Reader.swift
//  Kiwix for iOS
//
//  Created by Chris Li on 6/23/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

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
                if sidebarDisplayMode != nil, horizontalSizeClass == .regular {
                    HStack(spacing: 0) {
                        if sidebarDisplayMode == .outline {
                            Outline()
                        } else if sidebarDisplayMode == .bookmarks {
                            Bookmarks(url: $url)
                        }
                        Divider().ignoresSafeArea(.container, edges: .bottom)
                    }
                    .listStyle(.plain)
                    .frame(width: min(320, proxy.size.width * 0.35))
                    .transition(.move(edge: Edge.leading).combined(with: .opacity))
                }
                Group {
                    if url == nil {
                        Welcome(url: $url)
                    } else {
                        WebView(url: $url).ignoresSafeArea(.container, edges: .all)
                    }
                }.animation(.linear(duration: 0.1), value: sidebarDisplayMode)
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
                SheetView { Outline().listStyle(.plain).navigationBarTitleDisplayMode(.inline) }
            case .bookmarks:
                SheetView { Bookmarks(url: $url).listStyle(.plain).navigationBarTitleDisplayMode(.inline) }
            case .library:
                Library()
            case .settings:
                SheetView { Settings() }
            }
        }
        .environmentObject(viewModel)
        .onChange(of: horizontalSizeClass) { _ in
            if sheetDisplayMode == .outline || sheetDisplayMode == .bookmarks {
                sheetDisplayMode = nil
            }
        }
        .onOpenURL { url in
            if url.isFileURL {
                guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                LibraryViewModel.open(url: url)
                self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
            } else if url.scheme == "kiwix" {
                self.url = url
            }
            withAnimation {
                isSearchActive = false
                sheetDisplayMode = nil
            }
        }
    }
}
