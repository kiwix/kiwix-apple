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
    
    let context: OpenFileContext
    let label: Label
    
    init(context: OpenFileContext, @ViewBuilder label: () -> Label) {
        self.context = context
        self.label = label()
    }
    
    var body: some View {
        Button {
            // On iOS/iPadOS 15, fileimporter's isPresented binding is not reset to false if user swipe to dismiss
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
            NotificationCenter.openFiles(urls, context: context)
        }
        .help("Open a zim file")
        .keyboardShortcut("o")
    }
}


struct OpenFileHandler: ViewModifier {
    @State private var isAlertPresented = false
    @State private var activeAlert: ActiveAlert?
    
    private let importFiles = NotificationCenter.default.publisher(for: .openFiles)
    
    enum ActiveAlert {
        case unableToOpen(filenames: [String])
    }
    
    func body(content: Content) -> some View {
        content.onReceive(importFiles) { notification in
            guard let urls = notification.userInfo?["urls"] as? [URL] else { return }
            let invalidURLs = urls.filter({ ZimFileService.getMetaData(url: $0) == nil })
            
            // open files that are valid
            Set(urls).subtracting(invalidURLs).forEach { url in
                LibraryOperations.open(url: url)
            }
            
            // show alert if there are invalid files
            if !invalidURLs.isEmpty {
                isAlertPresented = true
                activeAlert = .unableToOpen(filenames: invalidURLs.map({ $0.lastPathComponent }))
            }
                
//            guard let metadata = ZimFileService.getMetaData(url: url) else { return }
//            LibraryOperations.open(url: url)
//            self.url = ZimFileService.shared.getMainPageURL(zimFileID: metadata.fileID)
        }.alert("Unable to open file", isPresented: $isAlertPresented, presenting: activeAlert) { _ in
        } message: { alert in
            switch alert {
            case .unableToOpen(let filenames):
                Text("\(ListFormatter.localizedString(byJoining: filenames)) cannot be opened.")
            }
        }
    }
}
