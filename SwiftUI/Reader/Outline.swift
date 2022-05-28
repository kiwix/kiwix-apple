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
        List(selection: $selectedID) {
            OutlineGroup(viewModel.outlineItems, children: \.children) { item in
                #if os(macOS)
                Text(item.text).id(item.id)
                #elseif os(iOS)
                Button(item.text) { viewModel.scrollTo(outlineItemID: item.id) }
                #endif
            }
        }.onChange(of: selectedID) { selectedID in
            guard let selectedID = selectedID else { return }
            viewModel.scrollTo(outlineItemID: selectedID)
            self.selectedID = nil
        }
    }
}

struct OutlineSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var viewModel: ReaderViewModel
    
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
