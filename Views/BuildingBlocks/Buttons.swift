//
//  Buttons.swift
//  Kiwix
//
//  Created by Chris Li on 2/13/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

import Defaults

struct FileImportButton<Label: View>: View {
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
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                isPresented = true
            }
        } label: { label }
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [UTType.zimFile],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            for url in urls {
                LibraryOperations.open(url: url)
            }
        }
        .help("Open a zim file")
        .keyboardShortcut("o")
    }
}
