//
//  Outline.swift
//  Kiwix
//
//  Created by Chris Li on 1/17/22.
//  Copyright © 2022 Chris Li. All rights reserved.
//

import SwiftUI

struct Outline: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var selectedID: String?
    
    var body: some View {
        if viewModel.outlineItems.isEmpty {
            Message(text: "No outline available")
        } else {
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
}

struct OutlineNode: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var item: OutlineItem
    
    var body: some View {
        if let children = item.children {
            DisclosureGroup(isExpanded: $item.isExpanded) {
                ForEach(children) { child in
                    OutlineNode(item: child)
                }
            } label: {
                #if os(macOS)
                Text(item.text)
                #elseif os(iOS)
                Button(item.text) {
                    viewModel.scrollTo(outlineItemID: item.id)
                    presentationMode.wrappedValue.dismiss()
                }
                #endif
            }.id(item.id)
        } else {
            #if os(macOS)
            Text(item.text).id(item.id)
            #elseif os(iOS)
            Button(item.text) {
                viewModel.scrollTo(outlineItemID: item.id)
                presentationMode.wrappedValue.dismiss()
            }.id(item.id)
            #endif
        }
    }
}

#if os(iOS)
struct OutlineSheet: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            Outline()
                .listStyle(.plain)
                .navigationTitle(viewModel.articleTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}
#endif
