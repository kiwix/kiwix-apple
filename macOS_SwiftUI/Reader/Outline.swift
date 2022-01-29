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
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $viewModel.selectedOutlineItemID) {
                ForEach(viewModel.outlineItems) { item in
                    OutlineNode(item: item)
                }
            }.onChange(of: viewModel.selectedOutlineItemID) { selectedID in
                proxy.scrollTo(selectedID)
            }
        }
    }
}

struct OutlineNode: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State var item: OutlineItem
    
    var body: some View {
        if let children = item.children {
            DisclosureGroup(item.text, isExpanded: $item.isExpanded) {
                ForEach(children) { child in
                    OutlineNode(item: child)
                }
            }.id(item.id)
        } else {
            Text(item.text).id(item.id)
        }
    }
}
