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
        Button { } label: {
            Image(systemName: isBookmarked ? "star.fill" : "star")
        }
        .simultaneousGesture(TapGesture().onEnded {
            if horizontalSizeClass == .regular {
                sidebarDisplayMode = sidebarDisplayMode != .bookmarks ? .bookmarks : nil
            } else {
                sheetDisplayMode = .bookmarks
            }
        })
        .simultaneousGesture(LongPressGesture().onEnded { _ in
            if isBookmarked {
                viewModel.deleteBookmark()
            } else {
                viewModel.createBookmark()
            }
        })
        .foregroundColor(isBookmarked ? .yellow : nil)
        .help("Show bookmarks. Long press to bookmark or unbookmark the current article.")
    }
    
    private var isBookmarked: Bool {
        !bookmarks.isEmpty
    }
}
#endif
