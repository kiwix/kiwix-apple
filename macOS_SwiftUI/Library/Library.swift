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

    let sections: [[DisplayMode]] = [
        [.opened, .featured, .new],
        Category.allCases.map {.category($0)}
    ]

    var body: some View {
        NavigationView {
            LibrarySidebar(displayMode: $displayMode)
                .frame(minWidth: 200)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { Kiwix.toggleSidebar() } label: { Image(systemName: "sidebar.leading") }
                    }
                }
            LibraryZimFiles(displayMode: $displayMode)
            Text("detail").frame(minWidth: 200)
        }.navigationSubtitle(displayMode?.description ?? "Unknown")
    }
    
    enum DisplayMode: CustomStringConvertible, Hashable {
        case opened, featured, new, downloads
        case category(Category)
        
        var description: String {
            switch self {
            case .opened:
                return "Opened"
            case .featured:
                return "Featured"
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
            case .featured:
                return "lightbulb"
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
