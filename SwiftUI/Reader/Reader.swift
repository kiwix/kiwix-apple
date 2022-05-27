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
    @StateObject var viewModel = ReaderViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Text("sidebar 1")
                Text("sidebar 2")
                Text("sidebar 3")
            }
            .frame(minWidth: 250)
            .toolbar { SidebarButton() }
            ReaderContent()
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
                WebView()
                    .ignoresSafeArea(.container, edges: .all)
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

//private struct ReaderContent: View {
//    @EnvironmentObject var viewModel: ReaderViewModel
//
//    var body: some View {
//        if viewModel.url == nil {
//            List {
//                Text("Welcome!")
//                Text("Zim File 1")
//                Text("Zim File 2")
//                Text("Zim File 3")
//            }
//        } else {
//            WebView(webView: viewModel.webView)
//                .ignoresSafeArea(.container, edges: .all)
//        }
//    }
//}
