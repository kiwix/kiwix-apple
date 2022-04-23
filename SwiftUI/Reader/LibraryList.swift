//
//  LibraryList.swift
//  kiwix for macOS
//
//  Created by Chris Li on 12/29/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct LibraryList: View {
    @Binding var url: URL?
    @State var selectedID: UUID?
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    
    var body: some View {
        List(zimFiles, selection: $selectedID) { zimFile in
            VStack(alignment: .leading) {
                Text(zimFile.name)
                Text(ByteCountFormatter().string(fromByteCount: zimFile.size))
            }
        }.onChange(of: selectedID) { zimFileID in
            guard let zimFileID = zimFileID else { return }
            url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID)
            selectedID = nil
        }
    }
}
