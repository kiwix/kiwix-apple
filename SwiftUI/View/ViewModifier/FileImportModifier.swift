//
//  FileImportModifier.swift
//  Kiwix
//
//  Created by Chris Li on 5/15/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileImportModifier: ViewModifier {
    @Binding var isShowing: Bool
    
    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isShowing,
            allowedContentTypes: [UTType(exportedAs: "org.openzim.zim")],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result,
                  let url = urls.first,
                  let metadata = ZimFileService.getMetaData(url: url),
                  let data = ZimFileService.getBookmarkData(url: url) else { return }
            ZimFileService.shared.open(bookmark: data)
            Database.shared.upsertZimFile(metadata: metadata, fileURLBookmark: data)
        }
        .keyboardShortcut("o")
    }
}
