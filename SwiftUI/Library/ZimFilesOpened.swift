//
//  ZimFilesOpened.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct ZimFilesOpened: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\ZimFile.size, order: .reverse)],
        predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "languageCode == %@", "en"),
            NSPredicate(format: "fileURLBookmark != nil")
        ]),
        animation: .easeInOut
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var isShowingFileImporter: Bool = false
    
    var body: some View {
        List(zimFiles) { zimFile in
            Text(zimFile.name)
        }.toolbar {
            Button {
                isShowingFileImporter = true
            } label: {
                Image(systemName: "plus")
            }
        }.modifier(FileImporter(isShowing: $isShowingFileImporter))
    }
}
