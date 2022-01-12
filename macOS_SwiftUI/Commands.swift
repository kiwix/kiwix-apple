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
                        guard let metadata = ZimFileService.getMetaData(url: url) else { return }
                        ZimFileService.shared.open(url: url)
                        Task {
                            let data = ZimFileService.shared.getFileURLBookmark(zimFileID: metadata.identifier)
                            try? await Database.shared.upsertZimFile(metadata: metadata, fileURLBookmark: data)
                        }
                    }
                }.keyboardShortcut("o")
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
        Button("Show Bookmark") { displayMode = .bookmark }
            .keyboardShortcut("2")
            .disabled(displayMode == nil)
        Button("Show Table of Contrnt") { displayMode = .tableOfContent }
            .keyboardShortcut("3")
            .disabled(displayMode == nil)
        Button("Show Library") { displayMode = .library }
            .keyboardShortcut("4")
            .disabled(displayMode == nil)
    }
}

struct NavigationCommandButtons: View {
    @FocusedValue(\.sceneViewModel) var sceneViewModel: ReaderViewModel?
    
    var body: some View {
        Button("Go Back") { sceneViewModel?.webView.goBack() }
            .keyboardShortcut("[")
        Button("Go Forward") { sceneViewModel?.webView.goForward() }
            .keyboardShortcut("]")
    }
}

struct SidebarDisplayModeKey: FocusedValueKey {
    typealias Value = Binding<SidebarDisplayMode>
}

struct SceneViewModelKey: FocusedValueKey {
    typealias Value = ReaderViewModel
}

extension FocusedValues {
    var sidebarDisplayMode: SidebarDisplayModeKey.Value? {
        get { self[SidebarDisplayModeKey.self] }
        set { self[SidebarDisplayModeKey.self] = newValue }
    }
    
    var sceneViewModel: SceneViewModelKey.Value? {
        get { self[SceneViewModelKey.self] }
        set { self[SceneViewModelKey.self] = newValue }
    }
}
