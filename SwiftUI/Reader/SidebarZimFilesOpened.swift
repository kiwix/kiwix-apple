//
//  SidebarZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/27/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct SidebarZimFilesOpened: View {
    @Binding var url: URL?
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\ZimFile.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil"),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State var selected: UUID?
    
    var body: some View {
        List(zimFiles, id: \.fileID, selection: $selected) { zimFile in
            ZimFileRow(zimFile)
        }
        .onChange(of: selected) { zimFileID in
            guard let zimFileID = zimFileID,
                  let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFileID) else { return }
            self.url = url
            selected = nil
        }
    }
}
