//
//  RandomArticleButton.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct RandomArticleButton: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>

    var body: some View {
        #if os(macOS)
        Button {
            browser.loadRandomArticle()
        } label: {
            Label("Random Article", systemImage: "die.face.5")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article")
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    browser.loadRandomArticle(zimFileID: zimFile.fileID)
                }
            }
        } label: {
            Label("Random Page", systemImage: "die.face.5")
        } primaryAction: {
            browser.loadRandomArticle()
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article")
        #endif
    }
}
