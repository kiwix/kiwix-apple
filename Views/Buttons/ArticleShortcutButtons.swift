//
//  ArticleShortcutButtons.swift
//  Kiwix
//
//  Created by Chris Li on 9/3/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct ArticleShortcutButtons: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @EnvironmentObject private var browser: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    let displayMode: DisplayMode

    enum DisplayMode {
        case mainArticle, randomArticle, mainAndRandomArticle
    }
    
    var body: some View {
        switch displayMode {
        case .mainArticle:
            mainArticle
        case .randomArticle:
            randomArticle
        case .mainAndRandomArticle:
            mainArticle
            randomArticle
        }
    }
    
    private var mainArticle: some View {
        #if os(macOS)
        Button {
            browser.loadMainArticle()
            dismissSearch()
        } label: {
            Label("Main Article".localized, systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article".localized)
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    browser.loadMainArticle(zimFileID: zimFile.fileID)
                    dismissSearch()
                }
            }
        } label: {
            Label("Main Article".localized, systemImage: "house")
        } primaryAction: {
            browser.loadMainArticle()
            dismissSearch()
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article".localized)
        #endif
    }
    
    var randomArticle: some View {
        #if os(macOS)
        Button {
            browser.loadRandomArticle()
            dismissSearch()
        } label: {
            Label("Random Article".localized, systemImage: "die.face.5")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article".localized)
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    browser.loadRandomArticle(zimFileID: zimFile.fileID)
                    dismissSearch()
                }
            }
        } label: {
            Label("Random Page".localized, systemImage: "die.face.5")
        } primaryAction: {
            browser.loadRandomArticle()
            dismissSearch()
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article".localized)
        #endif
    }
}
