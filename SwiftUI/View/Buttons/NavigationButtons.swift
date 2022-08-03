//
//  NavigationButtons.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct BookmarkToggleButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    
    private let url: URL?
    private var isBookmarked: Bool { !bookmarks.isEmpty }
    
    init(url: URL?) {
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
        self.url = url
    }
    
    var body: some View {
        Button {
            if isBookmarked {
                viewModel.deleteBookmark(url)
            } else {
                viewModel.createBookmark(url)
            }
        } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
                .renderingMode(isBookmarked ? .original : .template)
        }
        .disabled(url == nil)
        .help(isBookmarked ? "Remove bookmark" : "Bookmark the current article")
    }
}

struct BookmarkMultiButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    
    private let url: URL?
    private var isBookmarked: Bool { !bookmarks.isEmpty }
    
    init(url: URL?) {
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
        self.url = url
    }
    
    var body: some View {
        Button { } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
                .renderingMode(isBookmarked ? .original : .template)
        }
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.activeSheet = .bookmarks
        })
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            if isBookmarked {
                viewModel.deleteBookmark(url)
            } else {
                viewModel.createBookmark(url)
            }
        })
        .help("Show bookmarks. Long press to bookmark or unbookmark the current article.")
    }
}

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

struct OutlineButton: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    
    var body: some View {
        Button {
            viewModel.activeSheet = .outline
        } label: {
            Image(systemName: "list.bullet")
        }
        .disabled(viewModel.outlineItems.isEmpty)
        .help("Show article outline")
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
