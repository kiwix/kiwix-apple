//
//  OutlineTree.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct OutlineTree: View {
    @EnvironmentObject var viewModel: ReadingViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedID: String?
    
    var body: some View {
        if viewModel.outlineItems.isEmpty {
            Message(text: "No outline available")
        } else {
            List(selection: $selectedID) {
                ForEach(viewModel.outlineItemTree) { item in
                    OutlineNode(item: item) { item in
                        viewModel.scrollTo(outlineItemID: item.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle(viewModel.articleTitle)
            .onChange(of: selectedID) { selectedID in
                guard let selectedID = selectedID else { return }
                viewModel.scrollTo(outlineItemID: selectedID)
                self.selectedID = nil
            }
        }
    }
}

private struct OutlineNode: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @ObservedObject var item: OutlineItem
    
    let action: ((OutlineItem) -> Void)?
    
    var body: some View {
        if let children = item.children {
            DisclosureGroup(isExpanded: $item.isExpanded) {
                ForEach(children) { child in
                    OutlineNode(item: child, action: action)
                }
            } label: {
                #if os(macOS)
                Text(item.text)
                #elseif os(iOS)
                Button(item.text) { action?(item) }
                #endif
            }.id(item.id)
        } else {
            #if os(macOS)
            Text(item.text).id(item.id)
            #elseif os(iOS)
            Button(item.text) { action?(item) }.id(item.id)
            #endif
        }
    }
}
