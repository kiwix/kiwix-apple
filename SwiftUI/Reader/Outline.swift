//
//  Outline.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Outline: View {
    @Binding var url: URL?
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var selectedID: String?
    
    var body: some View {
        List(selection: $selectedID) {
            ForEach(viewModel.outlineItems) { item in
                OutlineNode(item: item)
            }
        }.onChange(of: selectedID) { selectedID in
            guard let selectedID = selectedID else { return }
            viewModel.scrollTo(outlineItemID: selectedID)
            self.selectedID = nil
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
