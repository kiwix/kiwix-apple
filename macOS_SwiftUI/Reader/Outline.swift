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
        List(selection: $viewModel.selectedOutlineItemID) {
            ForEach(viewModel.outlineItems) { item in
                OutlineNode(outlineItem: item)
            }
        }
    }
}

struct OutlineNode: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State var outlineItem: OutlineItem
    
    var body: some View {
        if let children = outlineItem.children {
            DisclosureGroup(outlineItem.text, isExpanded: $outlineItem.isExpanded) {
                ForEach(children) { child in
                    OutlineNode(outlineItem: child)
                }
            }
        } else {
            Text(outlineItem.text)
        }
    }
}
