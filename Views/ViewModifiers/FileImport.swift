//
//  FileImport.swift
//  Kiwix
//
//  Created by Chris Li on 8/18/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct OpenFileButton<Label: View>: View {
    @State private var isPresented: Bool = false
    
    let label: Label
    
    init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }
    
    var body: some View {
        Button {
            // On iOS 14 & 15, fileimporter's isPresented binding is not reset to false if user swipe to dismiss
            // the sheet. In order to mitigate the issue, the binding is set to false then true with a 0.1s delay.
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPresented = true
            }
        } label: { label }
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [UTType.zimFile],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            NotificationCenter.importFiles(urls)
        }
        .help("Open a zim file")
        .keyboardShortcut("o")
    }
}


struct OpenFileHandler: ViewModifier {
    private let importFiles = NotificationCenter.default.publisher(for: .importFiles)
    
    func body(content: Content) -> some View {
        content.onReceive(importFiles) { notification in
            guard let urls = notification.userInfo?["urls"] as? [URL] else { return }
            print(urls)
//            guard let metadata = ZimFileService.getMetaData(url: url) else { return }
//            LibraryOperations.open(url: url)
//            self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
        }
    }
}
