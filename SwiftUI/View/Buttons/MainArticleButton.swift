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
            loadMainPage()
        } label: {
            Label("Main Page", systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
        #elseif os(iOS)
        if #available(iOS 15.0, *) {
            Menu {
                ForEach(zimFiles) { zimFile in
                    Button(zimFile.name) { loadMainArticle(zimFileID: zimFile.fileID) }
                }
            } label: {
                Label("Main Page", systemImage: "house")
            } primaryAction: {
                loadMainArticle()
            }
            .disabled(zimFiles.isEmpty)
            .help("Show main article")
        } else {
            if zimFiles.count == 1 {
                Button {
                    loadMainArticle()
                } label: {
                    Label("Main Page", systemImage: "house")
                }
                .disabled(zimFiles.isEmpty)
                .help("Show main article")
            } else {
                Menu {
                    ForEach(zimFiles) { zimFile in
                        Button(zimFile.name) { loadMainArticle(zimFileID: zimFile.fileID) }
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
    
    private func loadMainArticle(zimFileID: UUID? = nil) {
        guard let zimFileID = zimFileID ?? UUID(uuidString: url?.host ?? "") ?? zimFiles.first?.fileID,
              let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
        self.url = url
    }
}
