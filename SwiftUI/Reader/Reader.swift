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
//                        BookmarkButton(url: $url)
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
    @ObservedObject var viewModel = ReaderViewModel()
    @State var isPresentingLibrary = false
    
    var body: some View {
        ReaderContent()
            .onOpenURL { url in
                viewModel.load(url)
                withAnimation {
                    isPresentingLibrary = false
                }
            }
            .modifier(ToolbarButtons(isPresentingLibrary: $isPresentingLibrary))
            .environmentObject(viewModel)
            .sheet(isPresented: $isPresentingLibrary) { Library() }
    }
}

private struct ToolbarButtons: ViewModifier {
    @Binding var isPresentingLibrary: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var viewModel: ReaderViewModel
    
    func body(content: Content) -> some View {
        if viewModel.isSearchActive {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { viewModel.cancelSearch?()}
                }
            }
        } else if horizontalSizeClass == .regular {
            content.toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    NavigateBackButton()
                    NavigateForwardButton()
                    Button { } label: { Image(systemName: "list.bullet") }
                    Button { } label: { Image(systemName: "star") }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { } label: { Image(systemName: "die.face.5") }
                    MainArticleButton()
                    Button { isPresentingLibrary = true } label: { Image(systemName: "folder") }
                    Button { } label: { Image(systemName: "gear") }
                }
            }
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Group {
                        NavigateBackButton()
                        Spacer()
                        NavigateForwardButton()
                    }
                    Spacer()
                    Group {
                        Button { } label: { Image(systemName: "list.bullet") }
                        Spacer()
                        Button { } label: { Image(systemName: "star") }
                        Spacer()
                        Button { } label: { Image(systemName: "die.face.5") }
                    }
                    Spacer()
                    Menu {
                        Button { } label: { Label("Main Page", systemImage: "house") }
                        Button { isPresentingLibrary = true } label: { Label("Library", systemImage: "folder") }
                        Button { } label: { Label("Settings", systemImage: "gear") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}
#endif

private struct ReaderContent: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    
    var body: some View {
        Group {
            if viewModel.url == nil {
                List {
                    Text("Welcome!")
                    Text("Zim File 1")
                    Text("Zim File 2")
                    Text("Zim File 3")
                }
            } else {
                WebView(webView: viewModel.webView)
                    .ignoresSafeArea(.container, edges: .vertical)
            }
        }
    }
}
