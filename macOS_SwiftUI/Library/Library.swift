//
//  Library.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    @State private var displayMode: DisplayMode? = .opened
    @State private var zimFile: ZimFile?
    @State var searchText: String = ""
    
    var body: some View {
        NavigationView {
            LibrarySidebar(displayMode: $displayMode)
                .frame(minWidth: 200)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { Kiwix.toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            zimFiles
                .frame(minWidth: 500, idealWidth: .infinity, minHeight: 400, idealHeight: 550)
                .searchable(text: $searchText)
            LibraryZimFileDetail(zimFile: $zimFile).frame(minWidth: 200, idealWidth: 300)
        }
        .navigationSubtitle(displayMode?.description ?? "Unknown")
        .task { try? await Database.shared.refreshZimFileCatalog() }
    }
    
    @ViewBuilder
    var zimFiles: some View {
        switch displayMode {
        case .category(let category) where category != .ted && category != .stackExchange:
            LibraryZimFilesGrid(displayMode: $displayMode, selectedZimFile: $zimFile, searchText: $searchText)
        default:
            LibraryZimFilesList(displayMode: $displayMode, selectedZimFile: $zimFile, searchText: $searchText)
        }
    }
    
    enum DisplayMode: CustomStringConvertible, Hashable {
        case opened, new, downloads
        case category(Category)
        
        var description: String {
            switch self {
            case .opened:
                return "Opened"
            case .new:
                return "New"
            case .downloads:
                return "Downloads"
            case .category(let category):
                return category.description
            }
        }
        
        var iconName: String {
            switch self {
            case .opened:
                return "laptopcomputer"
            case .new:
                return "newspaper"
            case .downloads:
                return "tray.and.arrow.down"
            case .category(_):
                return "book"
            }
        }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
