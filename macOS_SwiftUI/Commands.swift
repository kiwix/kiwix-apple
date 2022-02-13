//
//  Commands.swift
//  Kiwix
//
//  Created by Chris Li on 12/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportCommands: Commands {
    @State private var isShowing: Bool = false
    
    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Section {
                Button("Open...") {
                    isShowing = true
                }.fileImporter(
                    isPresented: $isShowing,
                    allowedContentTypes: [UTType(exportedAs: "org.openzim.zim")],
                    allowsMultipleSelection: true
                ) { result in
                    guard case let .success(urls) = result else { return }
                    urls.forEach { url in
                        guard let metadata = ZimFileService.getMetaData(url: url),
                              let data = ZimFileService.getBookmarkData(url: url) else { return }
                        ZimFileService.shared.open(bookmark: data)
                        Task {
                            try? await Database.shared.upsertZimFile(metadata: metadata, fileURLBookmark: data)
                        }
                    }
                }.keyboardShortcut("o")
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
