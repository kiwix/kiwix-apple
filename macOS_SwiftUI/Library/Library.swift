//
//  Library.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    @State private var displayMode: LibraryDisplayMode?

    let sections: [[LibraryDisplayMode]] = [
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
        }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
