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
                Text(browser.articleBookmarked ? 
                     "common.dialog.button.remove_bookmark".localized : "common.dialog.button.add_bookmark".localized)
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
                    Label("common.dialog.button.remove_bookmark".localized, systemImage: "star.slash.fill")
                }
            } else {
                Button {
                    browser.createBookmark()
                } label: {
                    Label("common.dialog.button.add_bookmark".localized, systemImage: "star")
                }
            }
            Button {
                isShowingPopOver = true
            } label: {
                Label("common.dialog.button.show_bookmarks".localized, systemImage: "list.star")
            }
        } label: {
            Label {
                Text("common.dialog.button.show_bookmarks".localized)
            } icon: {
                Image(systemName: browser.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(browser.articleBookmarked ? .original : .template)
            }
        } primaryAction: {
            isShowingPopOver = true
        }
        .help("bookmark_button.show.help".localized)
        .popover(isPresented: $isShowingPopOver) {
            NavigationView {
                Bookmarks().navigationBarTitleDisplayMode(.inline).toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingPopOver = false
                        } label: {
                            Text("common.button.done".localized).fontWeight(.semibold)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            if browser.articleBookmarked {
                                browser.deleteBookmark()
                            } else {
                                browser.createBookmark()
                            }
                        } label: {
                            Label {
                                Text(
                                    browser.articleBookmarked ?
                                    "common.dialog.button.remove_bookmark".localized :
                                        "common.dialog.button.add_bookmark".localized
                                )
                            } icon: {
                                Image(systemName: browser.articleBookmarked ? "star.fill" : "star")
                                    .renderingMode(browser.articleBookmarked ? .original : .template)
                            }
                        }.disabled(browser.url == nil)
                    }
                }
            }
            .frame(idealWidth: 360, idealHeight: 600)
            .modifier(MarkAsHalfSheet())
        }
        #endif
    }
}
