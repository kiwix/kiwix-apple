//
//  MainArticleButton.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct MainArticleButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        #if os(macOS)
        button
        #elseif os(iOS)
        if #available(iOS 15.0, *) {
            Menu {
                ForEach(zimFiles) { zimFile in
                    Button(zimFile.name) { viewModel.loadMainPage(zimFileID: zimFile.id) }
                }
            } label: {
                Label("Main Page", systemImage: "house")
            } primaryAction: {
                viewModel.loadMainPage()
            }
            .disabled(zimFiles.isEmpty)
            .help("Show main article")
        } else {
            if zimFiles.count == 1 {
                button
            } else {
                Menu {
                    ForEach(zimFiles) { zimFile in
                        Button(zimFile.name) { viewModel.loadMainPage(zimFileID: zimFile.id) }
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
    
    var button: some View {
        Button {
            viewModel.loadMainPage()
        } label: {
            Label("Main Page", systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
    }
}
