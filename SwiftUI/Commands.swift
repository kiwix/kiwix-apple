//
//  Commands.swift
//  Kiwix
//
//  Created by Chris Li on 12/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct ImportCommands: Commands {
    @State private var isShowing: Bool = false
    
    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Section {
                Button {
                    isShowing = true
                } label: {
                    Image(systemName: "plus")
                }.modifier(FileImporter(isShowing: $isShowing))
            }
        }
    }
}

struct SidebarDisplayModeCommandButtons: View {
    @FocusedBinding(\.sidebarDisplayMode) var displayMode: Sidebar.DisplayMode?
    
    var body: some View {
        Button("Search Articles") { displayMode = .search }
            .keyboardShortcut("1")
            .disabled(displayMode == nil)
        Button("Show Bookmark") { displayMode = .bookmark }
            .keyboardShortcut("2")
            .disabled(displayMode == nil)
        Button("Show Library") { displayMode = .library }
            .keyboardShortcut("3")
            .disabled(displayMode == nil)
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

struct SidebarDisplayModeKey: FocusedValueKey {
    typealias Value = Binding<Sidebar.DisplayMode>
}

struct ReaderViewModelKey: FocusedValueKey {
    typealias Value = ReaderViewModel
}

extension FocusedValues {
    var sidebarDisplayMode: SidebarDisplayModeKey.Value? {
        get { self[SidebarDisplayModeKey.self] }
        set { self[SidebarDisplayModeKey.self] = newValue }
    }
    
    var readerViewModel: ReaderViewModelKey.Value? {
        get { self[ReaderViewModelKey.self] }
        set { self[ReaderViewModelKey.self] = newValue }
    }
}
