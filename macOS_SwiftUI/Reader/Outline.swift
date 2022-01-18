//
//  Outlines.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 1/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Outline: View {
    @Binding var url: URL?
    @State var items = [OutlineItem]()
    @State var selected: Int?
    
    var body: some View {
        List(selection: $selected) {
            OutlineGroup(items, children: \.children) { item in
                Text(item.text)
            }
        }
        .onAppear { self.loadTableOfContents() }
        .onChange(of: url) { _ in self.loadTableOfContents() }
    }
    
    private func loadTableOfContents() {
        guard let url = url,
              let parser = try? Parser(url: url) else { items = []; return }
        self.items = parser.getHierarchicalOutlineItems()
    }
}
