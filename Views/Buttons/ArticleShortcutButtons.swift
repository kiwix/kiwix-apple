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

struct ArticleShortcutButtons: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>

    let displayMode: DisplayMode = Brand.hideRandomButton ? .mainArticle : .mainAndRandomArticle
    let loadMainArticle: @MainActor (UUID?) -> Void
    let loadRandomArticle: @MainActor (UUID?) -> Void

    enum DisplayMode {
        case mainArticle, mainAndRandomArticle
    }

    var body: some View {
        switch displayMode {
        case .mainArticle:
            mainArticle
        case .mainAndRandomArticle:
            mainArticle
            randomArticle
        }
    }

    private var mainArticle: some View {
        #if os(macOS)
        Button {
            loadMainArticle(nil)
            dismissSearch()
        } label: {
            Label(LocalString.article_shortcut_main_button_title, systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help(LocalString.article_shortcut_main_button_help)
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    loadMainArticle(zimFile.fileID)
                    dismissSearch()
                }
            }
        } label: {
            Label(LocalString.article_shortcut_main_button_title, systemImage: "house")
        } primaryAction: {
            loadMainArticle(nil)
            dismissSearch()
        }
        .disabled(zimFiles.isEmpty)
        .help(LocalString.article_shortcut_main_button_help)
        #endif
    }

    var randomArticle: some View {
        #if os(macOS)
        Button {
            loadRandomArticle(nil)
            dismissSearch()
        } label: {
            Label(LocalString.article_shortcut_random_button_title_mac, systemImage: "die.face.5")
        }
        .disabled(zimFiles.isEmpty)
        .help(LocalString.article_shortcut_random_button_help)
        .keyboardShortcut(KeyEquivalent("r"), modifiers: [.command, .option])

        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    loadRandomArticle(zimFile.fileID)
                    dismissSearch()
                }
            }
        } label: {
            Label(LocalString.article_shortcut_random_button_title_ios, systemImage: "die.face.5")
        } primaryAction: {
            loadRandomArticle(nil)
            dismissSearch()
        }
        .disabled(zimFiles.isEmpty)
        .help(LocalString.article_shortcut_random_button_help)
        #endif
    }
}
