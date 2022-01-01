//
//  Library.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 12/31/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

struct Library: View {
    @State private var selection: LibraryDisplayMode?

    let sections: [[LibraryDisplayMode]] = [
        [.opened, .featured, .new],
        Category.allCases.map {.category($0)}
    ]

    var body: some View {
        NavigationView {
            List(sections, id: \.self, selection: $selection) { section in
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
            ZimFileGrid()
        }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}
