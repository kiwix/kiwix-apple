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
            OutlineGroup(viewModel.outlineItems, children: \.children) { item in
                Text(item.text)
            }
        }
    }
}
