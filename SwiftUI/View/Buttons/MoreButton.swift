//
//  MoreButton.swift
//  Kiwix
//
//  Created by Chris Li on 5/26/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct MoreButton: View {
    @Binding var url: URL?
    @Binding var sheetDisplayMode: SheetDisplayMode?
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
                        url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID)
                    } label: {
                        Label(zimFile.name, systemImage: "house")
                    }
                }
            }
            Button { sheetDisplayMode = .library } label: { Label("Library", systemImage: "folder") }
            Button { sheetDisplayMode = .settings } label: { Label("Settings", systemImage: "gear") }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
