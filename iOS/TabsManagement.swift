//
//  TabsManagement.swift
//  Kiwix
//
//  Created by Chris Li on 7/29/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import CoreData
import SwiftUI

@available(iOS 16.0, *)
struct TabsSectionContent: View {
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Tab.created, order: .reverse)],
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    
    private struct Item {
        let tab: Tab
        let navigationItem: NavigationItem
        
        init(tab: Tab) {
            self.tab = tab
            self.navigationItem = NavigationItem.tab(objectID: tab.objectID)
        }
    }
    
    var body: some View {
        ForEach(tabs.map({ Item(tab: $0) }), id: \.navigationItem) { item in
            Group {
                if let zimFile = item.tab.zimFile, let category = Category(rawValue: zimFile.category) {
                    Label { Text(item.tab.title ?? "New Tab") } icon: {
                        Favicon(category: category, imageData: zimFile.faviconData).frame(width: 22, height: 22)
                    }
                } else {
                    Label(item.tab.title ?? "New Tab", systemImage: "square")
                }
            }
            .lineLimit(1)
            .swipeActions {
                Button(role: .destructive) {
                    Task { await navigation.deleteTab(objectID: item.tab.objectID) }
                } label: {
                    Label("Close Tab", systemImage: "xmark")
                }
            }
        }
    }
}

@available(iOS 16.0, *)
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
                        await navigation.deleteTab(objectID: tabID)
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
