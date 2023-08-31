//
//  TabsManagerButton.swift
//  Kiwix
//
//  Created by Chris Li on 9/1/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

#if os(iOS)
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
                    guard case .tab(let tabID) = navigation.currentItem else { return }
                    navigation.deleteTab(tabID: tabID)
                } label: {
                    Label("Close This Tab", systemImage: "xmark.square")
                }
                Button(role: .destructive) {
                    navigation.deleteAllTabs()
                } label: {
                    Label("Close All Tabs", systemImage: "xmark.square.fill")
                }
            }
            Section {
                ForEach(zimFiles.prefix(5)) { zimFile in
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
                NavigationView {
                    TabManager().toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                self.presentedSheet = nil
                            } label: {
                                Text("Done").fontWeight(.semibold)
                            }
                        }
                    }
                }.modifier(MarkAsHalfSheet())
            case .library:
                Library()
            case .settings:
                NavigationView {
                    Settings().toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                self.presentedSheet = nil
                            } label: {
                                Text("Done").fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TabManager: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var navigation: NavigationViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Tab.created, order: .reverse)],
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    
    var body: some View {
        List(tabs) { tab in
            Button {
                if #available(iOS 16.0, *) {
                    navigation.currentItem = NavigationItem.tab(objectID: tab.objectID)
                } else {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigation.currentItem = NavigationItem.tab(objectID: tab.objectID)
                    }
                }
            } label: {
                TabLabel(tab: tab)
            }
            .listRowBackground(
                navigation.currentItem == NavigationItem.tab(objectID: tab.objectID) ? Color.blue.opacity(0.2) : nil
            )
            .swipeActions {
                Button(role: .destructive) {
                    navigation.deleteTab(tabID: tab.objectID)
                } label: {
                    Label("Close Tab", systemImage: "xmark")
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Tabs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button(role: .destructive) {
                    guard case let .tab(tabID) = navigation.currentItem else { return }
                    navigation.deleteTab(tabID: tabID)
                } label: {
                    Label("Close This Tab", systemImage: "xmark.square")
                }
                Button(role: .destructive) {
                    navigation.deleteAllTabs()
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
}
#endif
