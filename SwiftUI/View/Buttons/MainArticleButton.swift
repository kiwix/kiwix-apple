//
//  MainArticleButton.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct MainArticleButton: View {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        #if os(macOS)
        Button {
            url = viewModel.getMainPageURL()
        } label: {
            Label("Main Page", systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
        #elseif os(iOS)
        if #available(iOS 15.0, *) {
            Menu {
                ForEach(zimFiles) { zimFile in
                    Button(zimFile.name) { url = viewModel.getMainPageURL(zimFileID: zimFile.id) }
                }
            } label: {
                Label("Main Page", systemImage: "house")
            } primaryAction: {
                url = viewModel.getMainPageURL()
            }
            .disabled(zimFiles.isEmpty)
            .help("Show main article")
        } else {
            if zimFiles.count == 1 {
                Button {
                    url = viewModel.getMainPageURL()
                } label: {
                    Label("Main Page", systemImage: "house")
                }
                .disabled(zimFiles.isEmpty)
                .help("Show main article")
            } else {
                Menu {
                    ForEach(zimFiles) { zimFile in
                        Button(zimFile.name) { url = viewModel.getMainPageURL(zimFileID: zimFile.id) }
                    }
                } label: {
                    Label("Main Page", systemImage: "house")
                }
                .disabled(zimFiles.isEmpty)
                .help("Show main article")
            }
        }
        #endif
    }
}
