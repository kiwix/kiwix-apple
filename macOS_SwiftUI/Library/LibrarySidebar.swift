//
//  LibrarySidebar.swift
//  macOS_SwiftUI
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct LibrarySidebar: View {
    @Binding var displayMode: LibraryDisplayMode?
    private let topDisplayModes: [LibraryDisplayMode] = [.opened, .featured, .new, .downloads]
    private let categories: [LibraryDisplayMode] = Category.allCases.map {.category($0)}
    
    var body: some View {
        List(selection: $displayMode) {
            ForEach(topDisplayModes, id: \.self) { displayMode in
                Label(displayMode.description, systemImage: displayMode.iconName)
            }
            Section("Category") {
                ForEach(categories, id: \.self) { displayMode in
                    Text(displayMode.description)
                }
            }
        }
    }
}

struct LibrarySidebar_Previews: PreviewProvider {
    static var previews: some View {
        LibrarySidebar(displayMode: .constant(.featured))
    }
}
