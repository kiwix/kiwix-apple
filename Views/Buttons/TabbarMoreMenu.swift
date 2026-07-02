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

#if os(iOS)
import SwiftUI

struct TabbarMoreMenu: View {
    
    @ObservedObject var browser: BrowserViewModel
    @FocusedValue(\.hasZIMFiles) var hasZimFiles
    
    /// For branded apps, that have a dedicated hotspot toolbar button
    let presentHotspot: () -> Void
    /// When the bookmark button is under more ... tab menu item
    let presentBookmarks: () -> Void
    
    var body: some View {
        if Brand.hideRandomButton && Brand.hideShareButton && FeatureFlags.hasLibrary {
            bookmarkButton()
        } else {
            menuOfButtons()
        }
    }
    
    @ViewBuilder
    private func menuOfButtons() -> some View {
        Menu {
            ControlGroup {
                if !Brand.hideRandomButton {
                    randomButton()
                }
                if !Brand.hideShareButton {
                    shareButton()
                }
                if !FeatureFlags.hasLibrary {
                    hotspotButton()
                }
                bookmarkMenuButton()
            }
            .controlGroupStyle(.compactMenu)
        } label: {
            Image(systemName: "ellipsis")
        }
    }
    
    @ViewBuilder
    private func randomButton() -> some View {
        Button(LocalString.article_shortcut_random_button_title_ios,
               systemImage: "die.face.5",
               action: { [weak browser] in browser?.loadRandomArticle() })
        .disabled(hasZimFiles == false)
        .accessibilityIdentifier("random")
    }
    
    @ViewBuilder
    private func shareButton() -> some View {
        ExportButton(
            articleTitle: browser.articleTitle,
            webViewURL: browser.webView.url,
            pageDataWithExtension: browser.pageDataWithExtension,
            isButtonDisabled: browser.zimFileName.isEmpty
        )
    }
    
    @ViewBuilder
    private func hotspotButton() -> some View {
        Button(
            LocalString.enum_navigation_item_hotspot,
            systemImage: "wifi",
            action: {
                presentHotspot()
            })
    }
    
    /// This is for the case when we have the star icon button on the tab bar directly (eg: custom apps)
    @ViewBuilder
    private func bookmarkButton() -> some View {
        BookmarkButton(articleBookmarked: browser.articleBookmarked,
                       isButtonDisabled: browser.zimFileName.isEmpty,
                       createBookmark: { [weak browser] in browser?.createBookmark() },
                       deleteBookmark: { [weak browser] in browser?.deleteBookmark() }
        )
    }
    
    /// This is for the case when the bookmark button is under more (...) as a menu item
    @ViewBuilder
    private func bookmarkMenuButton() -> some View {
        Button(LocalString.common_dialog_button_show_bookmarks, systemImage: "star") {
            presentBookmarks()
        }
    }
    
}
#endif
