//
//  NavigationButtons.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct NavigateBackButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.webView?.goBack()
        } label: {
            Image(systemName: "chevron.backward")
        }
        .disabled(!viewModel.canGoBack)
        .help("Show the previous page")
    }
}

struct NavigateForwardButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.webView?.goForward()
        } label: {
            Image(systemName: "chevron.forward")
        }
        .disabled(!viewModel.canGoForward)
        .help("Show the next page")
    }
}

struct OutlineMenu: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Menu {
            ForEach(viewModel.outlineItems) { item in
                Button(String(repeating: "    ", count: item.level) + item.text) {
                    viewModel.scrollTo(outlineItemID: item.id)
                }
            }
        } label: {
            Image(systemName: "list.bullet")
        }
        .disabled(viewModel.outlineItems.isEmpty)
        .help("Show article outline")
    }
}
