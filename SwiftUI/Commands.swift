//
//  Commands.swift
//  Kiwix
//
//  Created by Chris Li on 12/1/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

import Defaults

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

struct SidebarDisplayModeCommandButtons: View {
    @FocusedBinding(\.sidebarDisplayMode) var displayMode: SidebarDisplayMode?
    
    var body: some View {
        Button("Show Search") { displayMode = .search }
            .keyboardShortcut("1")
            .disabled(displayMode == nil)
        Button("Show Bookmark") { displayMode = .bookmarks }
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

struct SearchCommandButton: View {
    @FocusedValue(\.searchFieldFocusAction) var focusAction: (() -> Void)?
    @FocusedBinding(\.sidebarDisplayMode) var displayMode: SidebarDisplayMode?
    
    var body: some View {
        Button("Search") {
            displayMode = .search
            focusAction?()
        }
        .keyboardShortcut("s")
        .disabled(displayMode == nil)
    }
}

struct NavigationCommandButtons: View {
    @FocusedValue(\.canGoBack) var canGoBack: Bool?
    @FocusedValue(\.canGoForward) var canGoForward: Bool?
    @FocusedValue(\.readerViewModel) var readerViewModel: ReaderViewModel?
    
    var body: some View {
        Button("Go Back") { readerViewModel?.webView.goBack() }
            .keyboardShortcut("[")
            .disabled(!(canGoBack ?? false))
        Button("Go Forward") { readerViewModel?.webView.goForward() }
            .keyboardShortcut("]")
            .disabled(!(canGoForward ?? false))
    }
}

struct PageZoomCommandButtons: View {
    @Default(.webViewPageZoom) var webViewPageZoom
    @FocusedValue(\.url) var url: URL??
    
    var body: some View {
        Button("Actual Size") { webViewPageZoom = 1 }
            .keyboardShortcut("0")
            .disabled(webViewPageZoom == 1)
        Button("Zoom In") { webViewPageZoom += 0.1 }
            .keyboardShortcut("+")
            .disabled((url ?? nil) == nil)
        Button("Zoom Out") { webViewPageZoom -= 0.1 }
            .keyboardShortcut("-")
            .disabled((url ?? nil) == nil)
    }
}
