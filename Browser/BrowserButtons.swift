//
//  BrowserButtons.swift
//  Kiwix
//
//  Created by Chris Li on 7/23/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct NavigationButtons: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var viewModel: BrowserViewModel
    
    var body: some View {
        if horizontalSizeClass == .regular {
            goBackButton
            goForwardButton
        } else {
            goBackButton
            Spacer()
            goForwardButton
        }
    }
    
    var goBackButton: some View {
        Button {
            viewModel.webView.goBack()
        } label: {
            Label("Go Back", systemImage: "chevron.left")
        }.disabled(!viewModel.canGoBack)
    }
    
    var goForwardButton: some View {
        Button {
            viewModel.webView.goForward()
        } label: {
            Label("Go Forward", systemImage: "chevron.right")
        }.disabled(!viewModel.canGoForward)
    }
}

struct RandomArticleButton: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>

    var body: some View {
        #if os(macOS)
        Button {
            viewModel.loadRandomArticle()
        } label: {
            Label("Random Article", systemImage: "die.face.5")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article")
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    viewModel.loadRandomArticle(zimFileID: zimFile.fileID)
                }
            }
        } label: {
            Label("Random Page", systemImage: "die.face.5")
        } primaryAction: {
            viewModel.loadRandomArticle()
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article")
        #endif
    }
}

struct MainArticleButton: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Button {
            viewModel.loadMainArticle()
        } label: {
            Label("Main Article", systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
    }
}

struct OutlineButton: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var viewModel: BrowserViewModel
    @State private var isShowingOutline = false

    var body: some View {
        if horizontalSizeClass == .regular {
            Menu {
                ForEach(viewModel.outlineItems) { item in
                    Button(String(repeating: "    ", count: item.level) + item.text) {
                        viewModel.scrollTo(outlineItemID: item.id)
                    }
                }
            } label: {
                Label("Outline", systemImage: "list.bullet")
            }
            .disabled(viewModel.outlineItems.isEmpty)
            .help("Show article outline")
        } else {
            Button {
                isShowingOutline = true
            } label: {
                Image(systemName: "list.bullet")
            }
            .disabled(viewModel.outlineItems.isEmpty)
            .help("Show article outline")
            .sheet(isPresented: $isShowingOutline) {
                NavigationView {
                    Group {
                        if viewModel.outlineItemTree.isEmpty {
                            Message(text: "No outline available")
                        } else {
                            List(viewModel.outlineItemTree) { item in
                                OutlineNode(item: item) { item in
                                    viewModel.scrollTo(outlineItemID: item.id)
                                    isShowingOutline = false
                                }
                            }.listStyle(.plain)
                        }
                    }
                    .navigationTitle(viewModel.articleTitle)
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                isShowingOutline = false
                            } label: {
                                Text("Done").fontWeight(.semibold)
                            }
                        }
                    }
                }.modify { view in
                    #if os(macOS)
                    view
                    #elseif os(iOS)
                    if #available(iOS 16.0, *) {
                        view.presentationDetents([.medium, .large])
                    } else {
                        /*
                         HACK: Use medium as selection so that half sized sheets are consistently shown
                         when tab manager button is pressed, user can still freely adjust sheet size.
                        */
                        view.backport.presentationDetents([.medium, .large], selection: .constant(.medium))
                    }
                    #endif
                }
            }
        }
    }
    
    struct OutlineNode: View {
        @ObservedObject var item: OutlineItem

        let action: ((OutlineItem) -> Void)?
        
        var body: some View {
            if let children = item.children {
                DisclosureGroup(isExpanded: $item.isExpanded) {
                    ForEach(children) { child in
                        OutlineNode(item: child, action: action)
                    }
                } label: {
                    Button(item.text) { action?(item) }
                }
            } else {
                Button(item.text) { action?(item) }
            }
        }
    }
}

struct BookmarkButton: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var viewModel: BrowserViewModel
    @State private var isShowingBookmark = false
    
    var body: some View {
        #if os(macOS)
        Button {
            if viewModel.articleBookmarked {
                viewModel.deleteBookmark()
            } else {
                viewModel.createBookmark()
            }
        } label: {
            Label {
                Text(viewModel.articleBookmarked ? "Remove Bookmark" : "Add Bookmark")
            } icon: {
                Image(systemName: viewModel.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(viewModel.articleBookmarked ? .original : .template)
            }
        }
        #elseif os(iOS)
        Menu {
            if viewModel.articleBookmarked {
                Button(role: .destructive) {
                    viewModel.deleteBookmark()
                } label: {
                    Label("Remove Bookmark", systemImage: "star.slash.fill")
                }
            } else {
                Button {
                    viewModel.createBookmark()
                } label: {
                    Label("Add Bookmark", systemImage: "star")
                }
            }
            Button {
                isShowingBookmark = true
            } label: {
                Label("Show Bookmarks", systemImage: "list.star")
            }
        } label: {
            Label {
                Text("Show Bookmarks")
            } icon: {
                Image(systemName: viewModel.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(viewModel.articleBookmarked ? .original : .template)
            }
        } primaryAction: {
            isShowingBookmark = true
        }
        .help("Show bookmarks. Long press to bookmark or unbookmark the current article.")
        .popover(isPresented: $isShowingBookmark) {
            NavigationView {
                Bookmarks().toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingBookmark = false
                        } label: {
                            Text("Done").fontWeight(.semibold)
                        }
                    }
                }
            }
            .frame(idealWidth: 360, idealHeight: 600)
            .modify { view in
                if #available(iOS 16.0, *) {
                    view.presentationDetents([.medium, .large])
                } else {
                    view
                }
            }
        }
        #endif
    }
}
