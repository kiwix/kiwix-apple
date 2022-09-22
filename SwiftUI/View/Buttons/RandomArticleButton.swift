//
//  RandomArticleButton.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct RandomArticleButton: View {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            Menu {
                ForEach(zimFiles) { zimFile in
                    Button(zimFile.name) { loadRandomArticle(zimFileID: zimFile.fileID) }
                }
            } label: {
                Label("Random Page", systemImage: "die.face.5")
            } primaryAction: {
                loadRandomArticle()
            }
            .disabled(zimFiles.isEmpty)
            .help("Show random article")
        } else {
            if zimFiles.count == 1 {
                Button {
                    loadRandomArticle()
                } label: {
                    Label("Random Page", systemImage: "die.face.5")
                }
                .disabled(zimFiles.isEmpty)
                .help("Show random article")
            } else {
                Menu {
                    ForEach(zimFiles) { zimFile in
                        Button(zimFile.name) { loadRandomArticle(zimFileID: zimFile.fileID) }
                    }
                } label: {
                    Label("Random Page", systemImage: "die.face.5")
                }
                .disabled(zimFiles.isEmpty)
                .help("Show random article")
            }
        }
    }
    
    private func loadRandomArticle(zimFileID: UUID? = nil) {
        guard let zimFileID = zimFileID ?? UUID(uuidString: url?.host ?? "") ?? zimFiles.first?.fileID,
              let url = ZimFileService.shared.getRandomPageURL(zimFileID: zimFileID) else { return }
        self.url = url
    }
}
