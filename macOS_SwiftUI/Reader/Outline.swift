//
//  Outlines.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 1/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Outline: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @Binding var url: URL?
    @State var items = [OutlineItem]()
    @State var selectedIndex: Int?
    
    var body: some View {
        List(selection: $selectedIndex) {
            OutlineGroup(items, children: \.children) { item in
                Text(item.text)
            }
        }
        .onAppear { self.load() }
        .onChange(of: url) { _ in self.load() }
        .onChange(of: selectedIndex) { index in
            guard let index = index else { return }
            viewModel.navigate(outlineItemIndex: index)
        }
    }
    
    private func load() {
        guard let url = url,
              let parser = try? Parser(url: url) else { items = []; return }
        self.items = parser.getHierarchicalOutlineItems()
    }
}
