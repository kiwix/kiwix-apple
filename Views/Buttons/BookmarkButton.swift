//
//  BookmarkButton.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct BookmarkButton: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var browser: BrowserViewModel
    @State private var isShowingPopOver = false
    
    var body: some View {
        #if os(macOS)
        Button {
            if browser.articleBookmarked {
                browser.deleteBookmark()
            } else {
                browser.createBookmark()
            }
        } label: {
            Label {
                Text(browser.articleBookmarked ? "Remove Bookmark".localized : "Add Bookmark".localized)
            } icon: {
                Image(systemName: browser.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(browser.articleBookmarked ? .original : .template)
            }
        }
        #elseif os(iOS)
        Menu {
            if browser.articleBookmarked {
                Button(role: .destructive) {
                    browser.deleteBookmark()
                } label: {
                    Label("Remove Bookmark".localized, systemImage: "star.slash.fill")
                }
            } else {
                Button {
                    browser.createBookmark()
                } label: {
                    Label("Add Bookmark".localized, systemImage: "star")
                }
            }
            Button {
                isShowingPopOver = true
            } label: {
                Label("Show Bookmarks".localized, systemImage: "list.star")
            }
        } label: {
            Label {
                Text("Show Bookmarks".localized)
            } icon: {
                Image(systemName: browser.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(browser.articleBookmarked ? .original : .template)
            }
        } primaryAction: {
            isShowingPopOver = true
        }
        .help("Show bookmarks. Long press to bookmark or unbookmark the current article.".localized)
        .popover(isPresented: $isShowingPopOver) {
            NavigationView {
                Bookmarks().navigationBarTitleDisplayMode(.inline).toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingPopOver = false
                        } label: {
                            Text("Done".localized).fontWeight(.semibold)
                        }
                    }
                }
            }
            .frame(idealWidth: 360, idealHeight: 600)
            .modifier(MarkAsHalfSheet())
        }
        #endif
    }
}
