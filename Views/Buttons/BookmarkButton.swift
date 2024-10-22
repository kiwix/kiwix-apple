// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

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
            NavigationStack {
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
