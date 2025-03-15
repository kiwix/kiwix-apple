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
    @ObservedObject var browser: BrowserViewModel
    @State private var isShowingPopOver = false

    var body: some View {
        #if os(macOS)
        Button { [weak browser] in
            if browser?.articleBookmarked == true {
                browser?.deleteBookmark()
            } else {
                browser?.createBookmark()
            }
        } label: {
            Label {
                Text(browser.articleBookmarked ?
                     LocalString.common_dialog_button_remove_bookmark : LocalString.common_dialog_button_add_bookmark)
            } icon: {
                Image(systemName: browser.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(browser.articleBookmarked ? .original : .template)
            }
        }
        #elseif os(iOS)
        Menu {
            if browser.articleBookmarked {
                Button(role: .destructive) { [weak browser] in
                    browser?.deleteBookmark()
                } label: {
                    Label(LocalString.common_dialog_button_remove_bookmark, systemImage: "star.slash.fill")
                }
            } else {
                Button { [weak browser] in
                    browser?.createBookmark()
                } label: {
                    Label(LocalString.common_dialog_button_add_bookmark, systemImage: "star")
                }
            }
            Button {
                isShowingPopOver = true
            } label: {
                Label(LocalString.common_dialog_button_show_bookmarks, systemImage: "list.star")
            }
        } label: {
            Label {
                Text(LocalString.common_dialog_button_show_bookmarks)
            } icon: {
                Image(systemName: browser.articleBookmarked ? "star.fill" : "star")
                    .renderingMode(browser.articleBookmarked ? .original : .template)
            }
        } primaryAction: {
            isShowingPopOver = true
        }
        .help(LocalString.bookmark_button_show_help)
        .popover(isPresented: $isShowingPopOver) { [weak browser] in
            NavigationStack {
                Bookmarks().navigationBarTitleDisplayMode(.inline).toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingPopOver = false
                        } label: {
                            Text(LocalString.common_button_done).fontWeight(.semibold)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { [weak browser] in
                            if browser?.articleBookmarked == true {
                                browser?.deleteBookmark()
                            } else {
                                browser?.createBookmark()
                            }
                        } label: {
                            Label {
                                Text(
                                    browser?.articleBookmarked == true ?
                                    LocalString.common_dialog_button_remove_bookmark :
                                        LocalString.common_dialog_button_add_bookmark
                                )
                            } icon: {
                                Image(systemName: browser?.articleBookmarked == true ? "star.fill" : "star")
                                    .renderingMode(browser?.articleBookmarked == true ? .original : .template)
                            }
                        }.disabled(browser?.url == nil)
                    }
                }
            }
            .frame(idealWidth: 360, idealHeight: 600)
            .modifier(MarkAsHalfSheet())
        }
        #endif
    }
}
