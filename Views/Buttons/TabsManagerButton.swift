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
#endif

func getAvailableDiskSpace() -> Int64? {
    do {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let attributes = try fileManager.attributesOfFileSystem(forPath: documentsURL.path)
        
        if let freeSize = attributes[FileAttributeKey.systemFreeSize] as? Int64 {
            return freeSize
        }
    } catch {
        print("Error getting available disk space: \(error)")
    }
    
    return nil
}

struct TabManagerMacOS: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var navigation: NavigationViewModel
    //@EnvironmentObject private var browser: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Tab.created, order: .reverse)],
        animation: .easeInOut
    ) private var tabs: FetchedResults<Tab>
    
    
    var body: some View {
        Section("Library") {
            
            // Label("Close Tab", systemImage: "xmark")
            
            VStack(alignment: .leading) {
                ForEach(tabs, id: \.self) { tab in
                    Button {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            print("allo")
                            
                            if let availableDiskSpace = getAvailableDiskSpace() {
                                print("Available Disk Space: \(availableDiskSpace) bytes")
                                
                                // You can convert bytes to other units like megabytes or gigabytes as needed
                                let availableDiskSpaceMB = Double(availableDiskSpace) / 1_048_576 // 1 MB = 1,048,576 bytes
                                print("Available Disk Space: \(availableDiskSpaceMB) MB")
                            }
                            
                            /*navigation.currentItem = NavigationItem.tab(objectID: tab.objectID)
                             //browser.load(tab.url)
                             let zimFile = tab.zimFile
                             let url = ZimFileService.shared.getMainPageURL(zimFileID: zimFile?.fileID)
                             NotificationCenter.openURL(url)*/
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
            }
            
            List(tabs) { tab in
                Label("\(tab.title ?? "")", systemImage: "xmark")
            }
            /*
             LazyVGrid(
             columns: ([GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 12)]),
             alignment: .leading,
             spacing: 12
             ) {
             ForEach(tabs) { tab in
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
             //Label("foo", systemImage: "xmark")
             TabLabel(tab: tab)
             }
             .swipeActions {
             Button(role: .destructive) {
             navigation.deleteTab(tabID: tab.objectID)
             } label: {
             Label("Close Tab", systemImage: "xmark")
             }
             }
             }
             }
             .modifier(GridCommon(edges: .all))
             .modifier(ToolbarRoleBrowser())
             .navigationTitle(NavigationItem.opened.name)
             .overlay {
             if tabs.isEmpty {
             Message(text: "No opened zim file")
             }
             }
             */
            
            
            VStack(){
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
                        //Label("foo", systemImage: "xmark")
                        TabLabelForMacOS(tab: tab)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    
                }
            }
        }
    }
    
}

// TODO: faire une copie ?
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
                Label("foo", systemImage: "xmark")
                //TabLabel(tab: tab)
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
        .navigationTitle("TEST")
        //.navigationBarTitleDisplayMode(.inline)
        /*.toolbar {
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
         }*/
    }
}

