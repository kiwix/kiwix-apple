//
//  MoreButton.swift
//  Kiwix
//
//  Created by Chris Li on 5/26/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct MoreButton: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        Menu {
            Section {
                ForEach(zimFiles) { zimFile in
                    Button {
                        viewModel.loadMainPage(zimFileID: zimFile.id)
                    } label: {
                        Label(zimFile.name, systemImage: "house")
                    }
                }
            }
            Button { } label: { Label("Library", systemImage: "folder") }
            Button { } label: { Label("Settings", systemImage: "gear") }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
