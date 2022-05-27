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
    
    var body: some View {
        List(zimFiles.compactMap({ Item($0) }), selection: $url) { item in
            ZimFileRow(item.zimFile)
        }
    }
    
    struct Item: Hashable, Identifiable {
        let id: URL
        let zimFile: ZimFile
        
        init?(_ zimFile: ZimFile) {
            guard let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile.fileID) else { return nil }
            self.id = url
            self.zimFile = zimFile
        }
    }
}
