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
    @State var searchText = ""
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
                    ZStack {
                        List {}
                            .searchable(text: $searchText, placement: .sidebar, prompt: Text("Search")) {
                                Text("result 1")
                                Text("result 2")
                                Text("result 3")
                            }
                        List {
                            Text("sidebar 1")
                            Text("sidebar 2")
                            Text("sidebar 3")
                        }.padding(.top, 34)
                    }.listStyle(.sidebar)
                case .bookmark:
                    Text("bookmark")
                case .outline:
                    Outline(url: $url)
                case .library:
                    SidebarZimFilesOpened(url: $url)
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
}
#elseif os(iOS)
struct Reader: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject var viewModel = ReaderViewModel()
    @State var isPresentingLibrary = false
    @State var isPresentingSettings = false
    @State var url: URL?
    
    var body: some View {
        Group {
            if url == nil {
                Button("load main page") {
                    self.url = url
                }
            } else {
                WebView(url: $url).ignoresSafeArea(.container, edges: .all)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular {
                    NavigateBackButton()
                    NavigateForwardButton()
                    Button { } label: { Image(systemName: "list.bullet") }
                    BookmarkButton(url: url)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular {
                    RandomArticleButton(url: $url)
                    MainArticleButton(url: $url)
                    Button { isPresentingLibrary = true } label: { Image(systemName: "folder") }
                    Button { isPresentingSettings = true } label: { Image(systemName: "gear") }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if horizontalSizeClass == .compact {
                    Group {
                        NavigateBackButton()
                        Spacer()
                        NavigateForwardButton()
                        Spacer()
                        Button { } label: { Image(systemName: "list.bullet") }
                        Spacer()
                        BookmarkButton(url: url)
                        Spacer()
                        RandomArticleButton(url: $url)
                    }
                    Spacer()
                    MoreButton(url: $url, isPresentingLibrary: $isPresentingLibrary, isPresentingSettings: $isPresentingSettings)
                }
            }
        }
        .environmentObject(viewModel)
        .sheet(isPresented: $isPresentingLibrary) { Library() }
        .onOpenURL { url in
            self.url = url
            withAnimation {
                isPresentingLibrary = false
            }
        }
    }
}
#endif
