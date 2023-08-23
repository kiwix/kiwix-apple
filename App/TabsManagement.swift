//
//  TabsManagement.swift
//  Kiwix
//
//  Created by Chris Li on 7/29/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
struct TabLabel: View {
    let tab: Tab
    
    var body: some View {
        if let zimFile = tab.zimFile, let category = Category(rawValue: zimFile.category) {
            Label { Text(tab.title ?? "New Tab") } icon: {
                Favicon(category: category, imageData: zimFile.faviconData).frame(width: 22, height: 22)
            }
        } else {
            Label(tab.title ?? "New Tab", systemImage: "square")
        }
    }
}

struct NewTabButton: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    
    var body: some View {
        Menu {
            Button(role: .destructive) {
                Task { await navigation.deleteAllTabs() }
            } label: {
                Label("Close All Tabs", systemImage: "xmark.square.fill")
            }
        } label: {
            Label("New Tab", systemImage: "plus.square")
        } primaryAction: {
            navigation.createTab()
        }
    }
}

@available(iOS 16.0, *)
struct TabsManagerButton: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var presentedSheet: PresentedSheet?
    
    enum PresentedSheet: String, Identifiable {
        var id: String { rawValue }
        case tabsManager, library, settings
    }
    
    var body: some View {
        Menu {
            Section {
                Button {
                    navigation.createTab()
                } label: {
                    Label("New Tab", systemImage: "plus.square")
                }
                Button(role: .destructive) {
                    Task {
                        guard case .tab(let tabID) = navigation.currentItem else { return }
                        await navigation.deleteTab(tabID: tabID)
                    }
                } label: {
                    Label("Close This Tab", systemImage: "xmark.square")
                }
                Button(role: .destructive) {
                    Task { await navigation.deleteAllTabs() }
                } label: {
                    Label("Close All Tabs", systemImage: "xmark.square.fill")
                }
            }
            Section {
                ForEach(zimFiles) { zimFile in
                    Button {
                        browser.loadMainArticle(zimFileID: zimFile.fileID)
                    } label: { Label(zimFile.name, systemImage: "house") }
                }
            }
            Section {
                Button {
                    presentedSheet = .library
                } label: {
                    Label("Library", systemImage: "folder")
                }
                Button {
                    presentedSheet = .settings
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        } label: {
            Label("Tabs Manager", systemImage: "square.stack")
        } primaryAction: {
            presentedSheet = .tabsManager
        }
        .sheet(item: $presentedSheet) { presentedSheet in
            switch presentedSheet {
            case .tabsManager:
                SheetContent {
                    List(selection: $navigation.currentItem) {
                        TabsSectionContent()
                    }
                    .navigationTitle("Tabs")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { NewTabButton() }
                }.presentationDetents([.medium, .large])
            case .library:
                Library()
            case .settings:
                SheetContent { Settings() }
            }
        }
        .onChange(of: navigation.currentItem) { newValue in
            presentedSheet = nil
        }
    }
}
#endif
