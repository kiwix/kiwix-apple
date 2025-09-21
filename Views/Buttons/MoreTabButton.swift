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

struct MoreTabButton: View {
    
    let browser: BrowserViewModel
    @FocusedValue(\.hasZIMFiles) var hasZimFiles
    
    @State private var menuPopOver = false
    
    var body: some View {
        Button {
            menuPopOver = true
        } label: {
            Image(systemName: "ellipsis")
        }.popover(isPresented: $menuPopOver,
                  attachmentAnchor: .rect(.rect(CGRect(x: 0, y: 0, width: 184, height: 184)))
        ) {
            HStack(spacing: 24) {
                if !Brand.hideShareButton {
                    ExportButton(
                        webViewURL: browser.webView.url,
                        pageDataWithExtension: browser.pageDataWithExtension,
                        isButtonDisabled: browser.zimFileName.isEmpty,
                        actionCallback: {
                            menuPopOver = false
                        }
                    )
                }
                if !Brand.hideRandomButton {
                    Button(LocalString.article_shortcut_random_button_title_ios,
                           systemImage: "die.face.5",
                           action: { [weak browser] in browser?.loadRandomArticle() })
                    .disabled(hasZimFiles == false)
                }
                BookmarkButton(articleBookmarked: browser.articleBookmarked,
                               isButtonDisabled: browser.zimFileName.isEmpty,
                               createBookmark: { [weak browser] in browser?.createBookmark() },
                               deleteBookmark: { [weak browser] in browser?.deleteBookmark() })
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .tint(.primary)
            .padding(24)
            .presentationCompactAdaptation(.popover)
        }
    }
}
#endif
