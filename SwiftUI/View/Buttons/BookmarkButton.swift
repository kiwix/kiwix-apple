//
//  BookmarkButton.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/25/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

#if os(macOS)
struct BookmarkButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    
    private let url: URL?
    
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
                viewModel.deleteBookmark()
            } else {
                viewModel.createBookmark()
            }
        } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
        }
        .disabled(url == nil)
        .foregroundColor(isBookmarked ? .yellow : nil)
        .help(isBookmarked ? "Remove bookmark" : "Bookmark the current article")
    }
    
    private var isBookmarked: Bool {
        !bookmarks.isEmpty
    }
}
#elseif os(iOS)
struct BookmarkButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @FetchRequest private var bookmarks: FetchedResults<Bookmark>
    @Binding var sheetDisplayMode: SheetDisplayMode?
    @Binding var sidebarDisplayMode: SidebarDisplayMode?
    
    private let url: URL?
    
    init(url: URL?, sheetDisplayMode: Binding<SheetDisplayMode?>, sidebarDisplayMode: Binding<SidebarDisplayMode?>) {
        self._bookmarks = FetchRequest<Bookmark>(sortDescriptors: [], predicate: {
            if let url = url {
                return NSPredicate(format: "articleURL == %@", url as CVarArg)
            } else {
                return NSPredicate(format: "articleURL == nil")
            }
        }())
        self.url = url
        self._sheetDisplayMode = sheetDisplayMode
        self._sidebarDisplayMode = sidebarDisplayMode
    }
    
    var body: some View {
        Menu {
            if horizontalSizeClass == .regular {
                Button {
                    withAnimation(sidebarDisplayMode == nil ?  .easeOut(duration: 0.18) : .easeIn(duration: 0.18)) {
                        sidebarDisplayMode = sidebarDisplayMode != .bookmarks ? .bookmarks : nil
                    }
                } label: {
                    Label(
                        sidebarDisplayMode != .bookmarks ? "Show Bookmarks" : "Hide Bookmarks", systemImage: "list.star"
                    )
                }.help(sidebarDisplayMode != .bookmarks ? "Show bookmarks." : "Hide bookmarks.")
            } else {
                Button {
                    sheetDisplayMode = .bookmarks
                } label: {
                    Label("Show Bookmarks", systemImage: "list.star")
                }.help("Show bookmarks.")
            }
            if isBookmarked {
                Button {
                    viewModel.deleteBookmark()
                } label: {
                    Label("Remove Bookmark", systemImage: "star.slash.fill")
                }.help("Un-bookmark the current article.")
            } else {
                Button {
                    viewModel.createBookmark()
                } label: {
                    Label("Add Bookmark", systemImage: "star")
                }
                .disabled(url == nil)
                .help("Bookmark the current article.")
            }
        } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
                .foregroundColor(isBookmarked ? .yellow : nil)
        }
    }
    
    private var isBookmarked: Bool {
        !bookmarks.isEmpty
    }
}
#endif
