//
//  Commands.swift
//  Kiwix
//
//  Created by Chris Li on 12/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ImportCommands: Commands {
    @State private var isPresented: Bool = false
    
    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Section {
                Button("Open...") { isPresented = true}
                    .modifier(FileImporter(isPresented: $isPresented))
                    .keyboardShortcut("o")
            }
        }
    }
}

struct SidebarDisplayModeCommands: Commands {
    @FocusedBinding(\.sidebarDisplayMode) var displayMode: SidebarDisplayMode?
    
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button("Search Articles") { displayMode = .search }
                .keyboardShortcut("1")
                .disabled(displayMode == nil)
            Button("Show Bookmark") { displayMode = .bookmark }
                .keyboardShortcut("2")
                .disabled(displayMode == nil)
            Button("Show Outline") { displayMode = .outline }
                .keyboardShortcut("3")
                .disabled(displayMode == nil)
            Button("Show Library") { displayMode = .library }
                .keyboardShortcut("4")
                .disabled(displayMode == nil)
        }
    }
}

struct NavigationCommandButtons: View {
    @FocusedValue(\.readerViewModel) var readerViewModel: ReaderViewModel?
    
    var body: some View {
        Button("Go Back") { readerViewModel?.webView.goBack() }
            .keyboardShortcut("[").disabled(!(readerViewModel?.canGoBack ?? false))
        Button("Go Forward") { readerViewModel?.webView.goForward() }
            .keyboardShortcut("]").disabled(!(readerViewModel?.canGoForward ?? false))
    }
}

struct ReaderViewModelKey: FocusedValueKey {
    typealias Value = ReaderViewModel
}

extension FocusedValues {
    var readerViewModel: ReaderViewModelKey.Value? {
        get { self[ReaderViewModelKey.self] }
        set { self[ReaderViewModelKey.self] = newValue }
    }
}
