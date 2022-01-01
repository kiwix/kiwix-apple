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
    private let sections: [[LibraryDisplayMode]] = [
        [.opened, .featured, .new, .downloading],
        Category.allCases.map {.category($0)}
    ]
    
    var body: some View {
        List(sections, id: \.self, selection: $displayMode) { section in
            Section {
                ForEach(section, id: \.self) { item in
                    Text(item.description)
                }
            } header: {
                if section.count == Category.allCases.count {
                    Text("Category")
                } else {
                    EmptyView()
                }
            }.collapsible(false)
        }
    }
}

struct LibrarySidebar_Previews: PreviewProvider {
    static var previews: some View {
        LibrarySidebar(displayMode: .constant(.featured))
    }
}
