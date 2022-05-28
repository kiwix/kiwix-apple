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
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedID: String?
    
    var body: some View {
        if viewModel.outlineItems.isEmpty {
            Message(text: "No outline available")
        } else {
            List(selection: $selectedID) {
                OutlineGroup(viewModel.outlineItems, children: \.children) { item in
                    #if os(macOS)
                    Text(item.text).id(item.id)
                    #elseif os(iOS)
                    Button(item.text) {
                        viewModel.scrollTo(outlineItemID: item.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                    #endif
                }
            }.onChange(of: selectedID) { selectedID in
                guard let selectedID = selectedID else { return }
                viewModel.scrollTo(outlineItemID: selectedID)
                self.selectedID = nil
            }
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
