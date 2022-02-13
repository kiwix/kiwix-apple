//
//  Reader.swift
//  Kiwix
//
//  Created by Chris Li on 10/19/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI
import WebKit

struct Reader: View {
    @StateObject var viewModel = ReaderViewModel()
    @State var url: URL?
    @FetchRequest(sortDescriptors: []) private var onDeviceZimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        NavigationView {
            Sidebar(url: $url)
                .frame(minWidth: 250)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        SidebarButton()
                    }
                }
            WebView(url: $url, webView: viewModel.webView)
                .ignoresSafeArea(.container, edges: .vertical)
                .frame(minWidth: 400, idealWidth: 800, minHeight: 500, idealHeight: 550)
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        NavigateBackButton()
                        NavigateForwardButton()
                    }
                    ToolbarItemGroup {
                        BookmarkButton(url: $url)
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
