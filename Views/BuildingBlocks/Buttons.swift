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

struct NavigationCommandButtons: View {
    @FocusedValue(\.canGoBack) var canGoBack: Bool?
    @FocusedValue(\.canGoForward) var canGoForward: Bool?
    @FocusedValue(\.readingViewModel) var viewModel: ReadingViewModel?
    
    var body: some View {
        Button("Go Back") { viewModel?.goBack() }
            .keyboardShortcut("[")
            .disabled(!(canGoBack ?? false))
        Button("Go Forward") { viewModel?.goForward() }
            .keyboardShortcut("]")
            .disabled(!(canGoForward ?? false))
    }
}

#if os(macOS)
struct SidebarButton: View {
    var body: some View {
        Button {
            guard let responder = NSApp.keyWindow?.firstResponder else { return }
            responder.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        } label: {
            Image(systemName: "sidebar.leading")
        }
        .help("Show sidebar")
    }
}
#endif

struct SidebarNavigationItemButtons: View {
    @FocusedBinding(\.navigationItem) var navigationItem: NavigationItem??
    
    var body: some View {
        buildButtons([.reading, .bookmarks], modifiers: [.command])
        Divider()
        buildButtons([.opened, .categories, .downloads, .new], modifiers: [.command, .control])
    }
    
    private func buildButtons(_ navigationItems: [NavigationItem], modifiers: EventModifiers = []) -> some View {
        ForEach(Array(navigationItems.enumerated()), id: \.element) { index, item in
            Button(item.name) {
                navigationItem = item
            }
            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: modifiers)
            .disabled(navigationItem == nil)
        }
    }
}
