//
//  MainArticleButton.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct MainArticleButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Button {
            viewModel.loadMainPage()
        } label: {
            Image(systemName: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("Show main article")
    }
}
