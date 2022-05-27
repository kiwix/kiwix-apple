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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                VSplitView {
                    List {
                        Text("sidebar 1")
                        Text("sidebar 2")
                        Text("sidebar 3")
                    }
                    List {
                        Text("outline 1")
                        Text("outline 2")
                        Text("outline 3")
                    }
                }.listStyle(.sidebar)
            }
            .frame(minWidth: 250)
            .toolbar { SidebarButton() }
            Group {
                if viewModel.url == nil {
                    Button("load main page") {
                        viewModel.loadMainPage()
                    }
                } else {
                    WebView().ignoresSafeArea(.container, edges: .all)
                }
            }
            .frame(minWidth: 400, idealWidth: 800, minHeight: 500, idealHeight: 550)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    NavigateBackButton()
                    NavigateForwardButton()
                }
                ToolbarItemGroup {
                    BookmarkButton(url: viewModel.url)
                    MainArticleButton()
                    RandomArticleButton()
                }
            }
        }
        .environmentObject(viewModel)
        .focusedSceneValue(\.readerViewModel, viewModel)
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
    
    var body: some View {
        Group {
            if viewModel.url == nil {
                Button("load main page") {
                    viewModel.loadMainPage()
                }
            } else {
                WebView().ignoresSafeArea(.container, edges: .all)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if horizontalSizeClass == .regular {
                    NavigateBackButton()
                    NavigateForwardButton()
                    Button { } label: { Image(systemName: "list.bullet") }
                    BookmarkButton(url: viewModel.url)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if horizontalSizeClass == .regular {
                    RandomArticleButton()
                    MainArticleButton()
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
                        BookmarkButton(url: viewModel.url)
                        Spacer()
                        RandomArticleButton()
                    }
                    Spacer()
                    MoreButton(isPresentingLibrary: $isPresentingLibrary, isPresentingSettings: $isPresentingSettings)
                }
            }
        }
        .environmentObject(viewModel)
        .sheet(isPresented: $isPresentingLibrary) { Library() }
        .onOpenURL { url in
            viewModel.load(url)
            withAnimation {
                isPresentingLibrary = false
            }
        }
    }
}
#endif
