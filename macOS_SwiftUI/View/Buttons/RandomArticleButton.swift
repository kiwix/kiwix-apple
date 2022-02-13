//
//  RandomArticleButton.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct RandomArticleButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
        @FetchRequest(
            sortDescriptors: [SortDescriptor(\.size, order: .reverse)],
            predicate: NSPredicate(format: "fileURLBookmark != nil")
        ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) { viewModel.loadRandomPage(zimFileID: zimFile.id) }
            }
        } label: {
            Label("Random Page", systemImage: "die.face.5")
        } primaryAction: {
            guard let zimFile = zimFiles.first else { return }
            viewModel.loadRandomPage(zimFileID: zimFile.fileID)
        }
        .disabled(zimFiles.isEmpty)
        .help("Show random article")
    }
}
