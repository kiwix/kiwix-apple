//
//  LibraryPrimaryView.swift
//  Kiwix
//
//  Created by Chris Li on 4/10/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct LibraryPrimaryView: View {
    var categorySelected: (ZimFile.Category) -> Void = { _ in }
    
    var body: some View {
        List {
            Section(header: Text("Categories")) {
                ForEach(ZimFile.Category.allCases) { category in
                    Button(action: { categorySelected(category) }, label: {
                        HStack {
                            Favicon(uiImage: category.icon)
                            Text(category.description).foregroundColor(.primary)
                            Spacer()
                            DisclosureIndicator()
                        }
                    })
                }
            }
        }.listStyle(GroupedListStyle())
    }
}
