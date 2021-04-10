//
//  LibrarySidebarView.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct LibrarySidebarView: View {
    var body: some View {
        List {
            Section(header: Text("Categories")) {
                ForEach(ZimFile.Category.allCases) { category in
                    HStack {
                        Favicon(uiImage: category.icon)
                        Text(category.description)
                        Spacer()
                        DisclosureIndicator()
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}
