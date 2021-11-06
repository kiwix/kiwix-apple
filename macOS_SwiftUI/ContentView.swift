//
//  ContentView.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = SceneViewModel()
    
    var body: some View {
        NavigationView {
            Sidebar()
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            WebView()
                .ignoresSafeArea(.container, edges: .vertical)
                .frame(idealWidth: 800, minHeight: 300, idealHeight: 350)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { viewModel.action = .back } label: {
                            Image(systemName: "chevron.backward")
                        }.disabled(!viewModel.canGoBack)
                        Button { viewModel.action = .forward } label: {
                            Image(systemName: "chevron.forward")
                        }.disabled(!viewModel.canGoForward)
                    }
                    ToolbarItemGroup {
                        Button { viewModel.action = .main() } label: { Image(systemName: "house") }
                        Button { } label: { Image(systemName: "die.face.5") }
                    }
                }
        }
        .environmentObject(viewModel)
        .navigationTitle(viewModel.articleTitle ?? "")
        .navigationSubtitle(viewModel.zimFileTitle ?? "")
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

class SceneViewModel: ObservableObject {
    @Published var action: WebViewAction?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var articleTitle: String?
    @Published var zimFileTitle: String?
}
