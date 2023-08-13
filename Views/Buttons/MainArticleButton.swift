//
//  MainArticleButton.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct MainArticleButton: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        #if os(macOS)
        Button {
            browser.loadMainArticle()
        } label: {
            Label("Main Article", systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    browser.loadMainArticle(zimFileID: zimFile.fileID)
                }
            }
        } label: {
            Label("Main Article", systemImage: "house")
        } primaryAction: {
            browser.loadMainArticle()
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
        #endif
    }
}
